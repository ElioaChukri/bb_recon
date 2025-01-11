#!/bin/bash

# To handle discrepancies in httpx naming
# shellcheck disable=SC2140
alias "httpx-pd"="httpx"

# Telegram bot variables
TOKEN="<TELEGRAM-TOKEN>"
CHAT_ID="<TELEGRAM-CHAT-ID>"
GH_API_KEY="<GITHUB-API-KEY>"
SHODAN_API_KEY="<SHODAN-API-KEY>"

# Default values for options
SUBS=true
ROOT=""
XNLINK_WAYMORE=true
NEW_SUBDOMAINS=false

#TODO: Add log_and_run function that will log all commands ran in a file

# Log function (appends messages to the log file)
log() {
    local msg="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
}

# Usage information
usage() {
  log "Usage: $0 <target_domain> [-n (no subdomains)] [-p (path)] [-h (help)]"
    exit 1
}

# Telegram notification function
notify() {
  curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id="$CHAT_ID" -d text="$1" > /dev/null
}

# Check if help flag is at $1
if [ "$1" == "-h" ]; then
    usage
fi

# Check if the domain is provided
if [ -z "$1" ]; then
    usage
else
    DOMAIN="$1"
#    URL="https://$1"
    shift # Shift off the domain
fi

# Parse options
OPTIND=1
while getopts ":np:h:" opt; do
  case $opt in
    n) SUBS=false
       ;;
    h) usage
       ;;
    p) ROOT="$OPTARG"
       ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        usage
        ;;
    :) echo "Option -$OPTARG requires an argument." >&2
       usage
       ;;
  esac
done

# Set the log file path
if [ -z "$ROOT" ]; then
  LOG_FILE="$HOME/recon.log"
else
  LOG_FILE="$ROOT/recon.log"
fi

domainpath="$ROOT/$DOMAIN"


if [ "$SUBS" = "true" ]; then

  # Create dir if it doesn't exist
  mkdir -p "$domainpath"

  # Run amass and assetfinder on the target_domain and save the output in a file
  log "[*] Running amass and assetfinder on \"$DOMAIN\"..."

  amass enum -active -d "$DOMAIN" -timeout 15 -config ./configs/amass_config.yaml || log "[!] Amass failed"
  assetfinder --subs-only "$DOMAIN" | tee -a "$domainpath"/assetfinder.txt || log "[!] Assetfinder failed"

  log "[*] Finished running amass and assetfinder"

  # Get amass subdomain output 
  oam_subs -nocolor -d "$DOMAIN" -names | tee -a "$domainpath"/oamass.txt

  # Run github-subdomains.py on the target_domain and save the output in a file 
  log "[*] Running github-subdomains.py on \"$DOMAIN\"..."
  python3 ./scripts/github-subdomains.py -t $GH_API_KEY -d "$DOMAIN" | tee -a "$domainpath"/github-subdomains.txt

  # Run shosubgo on the target_domain and save the output in a file 
  log "[*] Running shosubgo on \"$DOMAIN\"..."
  shosubgo -d "$DOMAIN" -s $SHODAN_API_KEY | tee -a "$domainpath"/shosubgo.txt

  # Combine the output of all tools and remove any duplicates, performing needed transformation on files
  log "[*] Combining the results of all tools..."
  cat "$domainpath"/oamass.txt "$domainpath"/assetfinder.txt "$domainpath"/github-subdomains.txt "$domainpath"/shosubgo.txt | sort -u >> "$domainpath"/subdomains.txt
  rm "$domainpath"/assetfinder.txt "$domainpath"/oamass.txt "$domainpath"/github-subdomains.txt "$domainpath"/shosubgo.txt

  # Remove any duplicates from past runs and any non-domain lines (from potential program errors)
  sort -u "$domainpath"/subdomains.txt -o "$domainpath"/subdomains.txt
  cat "$domainpath"/subdomains.txt | grep "$DOMAIN" >> "$domainpath"/tmp.txt
  rm "$domainpath"/subdomains.txt
  mv "$domainpath"/tmp.txt "$domainpath"/subdomains.txt

fi

# If the subdomains flag is set to false, skip the subdomain enumeration, but still run httpx on the domain
if [ $SUBS = false ]; then
  log "[*] Skipping subdomain enumeration..."
  domainpath="$ROOT/domains"

  # Create dir if it doesn't exist
  mkdir -p "$domainpath"

  echo "$DOMAIN" >> "$domainpath"/subdomains.txt

  # Check if all domains have been processed
  domcount=$(wc -l "$ROOT/domains.txt" | cut -d " " -f 1)
  localcount=$(wc -l "$ROOT/domains/subdomains.txt" | cut -d " " -f 1)

  if [ "$domcount" -eq "$localcount" ]; then
    log "[*] All ${domcount} domains have been processed. Proceeding with recon"
  else
    log "[*] Some domains have not been processed yet, skipping rest of recon"
    exit 0
  fi
fi

# Run httpx on the subdomains to check which ones are alive and save the output in a file
log "[*] Running httpx on the subdomains..."
httpx -l "$domainpath"/subdomains.txt -threads 10 -timeout 10 -follow-redirects -no-color -o "$domainpath"/httpx_detailed.txt -sc -cl -title -td || log "[!] Httpx failed"

# Get additional ip address ranges from shodan
log "[*] Getting additional ip address ranges from shodan..."
shodan search ssl.cert.subject.cn:"$DOMAIN" 200 --fields ip_str | httpx -no-color -sc -cl -title -o "$domainpath"/shodan_httpx_detailed.txt -td

# Clean httpx files
cat "$domainpath"/httpx_detailed.txt | cut -d " " -f 1 | sort -u >> "$domainpath"/httpx.txt
cat "$domainpath"/shodan_httpx_detailed.txt | cut -d " " -f 1 | sort -u >> "$domainpath"/shodan.txt
cat "$domainpath"/shodan.txt "$domainpath"/httpx.txt | sort -u >> "$domainpath"/httpx_tmp.txt
mv -f "$domainpath"/httpx_tmp.txt "$domainpath"/httpx.txt
rm "$domainpath"/shodan.txt

log "[*] Saving the results in $DOMAIN/alive.txt..."
# Strip the protocol from the httpx output
sed 's/https\?:\/\///g' "$domainpath"/httpx.txt | sort -u >> "$domainpath"/alive_new.txt

if [ "$SUBS" = "false" ]; then
  log "[*] Skipping subdomains diff"

else
  if [ -f "$domainpath"/alive.txt ]; then 
    cat "$domainpath"/alive.txt | sort -u > "$domainpath"/alive_tmp.txt 

    if ! diff "$domainpath"/alive_tmp.txt "$domainpath"/alive_new.txt > /dev/null; then
      log "[*] New subdomains found. Notifying..."
      comm -13 <(sort "$domainpath/alive_tmp.txt") <(sort "$domainpath/alive_new.txt") > "$domainpath/alive_diff.txt"

      current_date=$(date "+%Y-%m-%d")
      message="New subdomain(s) found for $DOMAIN on $current_date:%0a%0a"
      NEW_SUBDOMAINS=true

      while IFS= read -r line; do
        message+="$line%0a%0a"
      done < "$domainpath/alive_diff.txt"

      notify "$message"
      rm "$domainpath"/alive_diff.txt

    rm "$domainpath"/alive_tmp.txt

  else 
    log "[*] Previous alive.txt file not found. First run?"
    NEW_SUBDOMAINS=true
  fi 
fi

mv -f "$domainpath"/alive_new.txt "$domainpath"/alive.txt

# Check if "alive.txt" contains only one subdomain entry and tag the dirname
lines=$(wc -l < "$domainpath"/alive.txt)

if [ "$lines" -eq 1 ]; then 
  mv -f "$domainpath" "$ROOT/_$DOMAIN"
  domainpath="$ROOT/_$DOMAIN"
fi

if [ "$NEW_SUBDOMAINS" = false ]; then
  log "[*] No new subdomains found. Skipping further recon"
  exit 0
fi

# Use gowitness to take screenshots of found subdomains
log "[*] Running gowitness on the subdomains..."
gowitness scan file -f "$domainpath/alive.txt" \
        --chrome-path /snap/bin/chromium \
        --delay 5 --screenshot-fullpage \
        --write-db --screenshot-path "$domainpath/gowitness"
log "[*] Screenshots saved in $domainpath/gowitness"

log "[*] Running katana on the subdomains..."
mkdir "$domainpath/katana/" "$domainpath/katana/responses/"
katana -u "$domainpath/httpx.txt" -depth 5 -js-crawl -known-files all -retry 2 \
        -strategy breadth-first -xhr -ef css,jpg,jpeg,png,woff,svg,woff2,gif \
        -field-scope rdn -field qurl -no-color -jsonl \
        -form-extraction -ignore-query-params -omit-body \
        -store-response -store-response-dir "$domainpath/katana/responses/" \
        -output "$domainpath/katana/katana.jsonl" || log "[!] Katana failed"
log "[*] Katana scan complete"

# Source the python env to be able to run python tools
source "$HOME/.venv/bin/activate"

# Run waymore on wildcards.txt

# wayback machine is down, can't use waymore
# Check if wildcards.txt is empty before running waymore on it
#if [ -s "$ROOT/wildcards.txt" ]; then
#  log "[*] Running waymore on the wildcards..."
#  mkdir "$ROOT/waymore/" "$ROOT/waymore/responses/"
#  waymore --input "$ROOT/wildcards.txt" -mode R --output-urls "$ROOT/waymore/urls.txt" \
#          --output-responses "$ROOT/waymore/responses/" --timeout 20 --limit-requests 5000 \
#          --config "./configs/waymore_config.yml" --limit 3000
#  log "[*] Waymore scan complete"
#else
#  log "[*] No wildcard domains found. Skipping waymore scan"
#  XNLINK_WAYMORE=false
#fi
XNLINK_WAYMORE=false

# Combine all domains and wildcards into a temp file to use in xnLinkFinder scoping
cat "$ROOT/wildcards.txt" "$ROOT/domains.txt" | sort -u > "$ROOT/tmp.txt"

# Run xnLinkFinder on both waymore and katana responses
log "[*] Running xnLinkFinder on the waymore and katana responses..."


# Check first if we did run waymore or not
if [ "$XNLINK_WAYMORE" = true ]; then
  log "[*] Running on waymore responses..."
  mkdir "$domainpath/xnLinkFinder/"
  xnLinkFinder -i "$ROOT/waymore/responses/" -o "$domainpath/xnLinkFinder/waymore_links.txt" \
        --output-params "$domainpath/xnLinkFinder/waymore_params.txt" \
        --output-wordlist "$domainpath/xnLinkFinder/waymore_wordlist.txt" \
        --scope-filter "$ROOT/wildcards.txt" --scope-prefix "$ROOT/wildcards.txt" -s429 -sTO -sCE \
        --config "./configs/linkfinder_config.yml"
fi

log "[*] Running on katana responses..."
find "$ROOT" -type d -name responses | while read -r line; do
  dirname=$(echo -n "$line" | awk -F '/' '{print $7}')
  mkdir -p "$domainpath/xnLinkFinder/$dirname"
  for dir in "$line"/*/; do
    echo "DIRECTORY: $dir"
    echo "CURRENT WORKING DIRECTORY: $PWD"
    echo "LISTING OF TARGET DIRECTORY: $(ls -l $dir)"
    xnLinkFinder -i "$dir" -o "$domainpath/xnLinkFinder/$dirname/${dir}_links.txt" \
          --output-params "$domainpath/xnLinkFinder/$dirname/${dir}_params.txt" \
          --output-wordlist "$domainpath/xnLinkFinder/$dirname/${dir}_wordlist.txt" \
          --scope-filter "$ROOT/tmp.txt" --scope-prefix "$ROOT/tmp.txt" -s429 -sTO -sCE \
          --config "$HOME/recon/configs/linkfinder_config.yml"
    done
done
log "[*] xnLinkFinder scan complete"

# Merge all the linkfinder wordlists
log "[*] Merging all the linkfinder wordlists..."
find "$domainpath/xnLinkFinder" -type f -regex ".*wordlist.txt" -exec cat {} \; | sort -u > "$domainpath/xnLinkFinder/wordlist.txt"

# Merge all the linkfinder links
log "[*] Merging all the linkfinder links..."
find "$domainpath/xnLinkFinder" -type f -regex ".*links.txt" -exec cat {} \; | sort -u > "$domainpath/xnLinkFinder/links.txt"

# Merge all the linkfinder params
log "[*] Merging all the linkfinder params..."
find "$domainpath/xnLinkFinder" -type f -regex ".*params.txt" -exec cat {} \; | sort -u > "$domainpath/xnLinkFinder/params.txt"

# Deactivate the python env once done with python tools
deactivate

#TODO: Add gf runs to extract interesting data from responses

log "[*] Recon complete for $DOMAIN"
