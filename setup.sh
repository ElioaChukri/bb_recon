#!/usr/bin/env bash

# Color variables
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

# API Keys
SHODAN_API_KEY="<SHODAN_API_KEY>"

# Check if root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[-] Please run as root${RESET}"
  exit 1
fi

# Get script directory and cd to it
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
USER_HOME=$(eval echo ~"$SUDO_USER")
export HOME="$USER_HOME"

# Runs on Monday, Wednesday, and Saturday at 2 AM
CRON_JOB="0 2 * * 1,3,6 $HOME/recon/cronner.sh"

# Install go
install_go() {
  if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Go...${RESET}"
    rm -rf /usr/local/go 2> /dev/null
    wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
    rm go1.22.3.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
    echo -e "${GREEN}[+] Go installed${RESET}"
  else
    echo -e "${GREEN}[+] Go already installed${RESET}"
  fi
}

# Install python3
install_python3() {
  apt-get install python3-venv -y
  if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Python3...${RESET}"
    apt-get install python3 -y
    echo -e "${GREEN}[+] Python3 installed${RESET}"
  else
    echo -e "${GREEN}[+] Python3 already installed${RESET}"
  fi
}

# Install chromium
install_chromium() {
  if ! command -v chromium-browser &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Chromium...${RESET}"
    apt-get install chromium-browser -y
    echo -e "${GREEN}[+] Chromium installed${RESET}"
  else
    echo -e "${GREEN}[+] Chromium already installed${RESET}"
  fi
}

# Install sqlite
install_sqlite() {
  if ! command -v sqlite3 &> /dev/null; then
    echo -e "${YELLOW}[+] Installing SQLite...${RESET}"
    apt-get install sqlite3 -y
    echo -e "${GREEN}[+] SQLite installed${RESET}"
  else
    echo -e "${GREEN}[+] SQLite already installed${RESET}"
  fi
}

# Install pip
install_pip() {
  if ! command -v pip &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Pip...${RESET}"
    apt-get install python3-pip -y
    echo -e "${GREEN}[+] Pip installed${RESET}"
  else
    echo -e "${GREEN}[+] Pip already installed${RESET}"
  fi
}

# Install amass
install_amass() {
  if [ ! -f "$HOME/go/bin/amass" ]; then
    echo -e "${YELLOW}[+] Installing Amass...${RESET}"
    go install -v github.com/owasp-amass/amass/v4/...@master
    echo -e "${GREEN}[+] Amass installed${RESET}"
  else
    echo -e "${GREEN}[+] Amass already installed${RESET}"
  fi
}

# Install oam tools
install_oam_tools() {
  if [ ! -f "$HOME/go/bin/oam_subs" ]; then
    echo -e "${YELLOW}[+] Installing OAM tools...${RESET}"
    go install -v github.com/owasp-amass/oam-tools/cmd/...@master
    echo -e "${GREEN}[+] OAM tools installed${RESET}"
  else
    echo -e "${GREEN}[+] OAM tools already installed${RESET}"
  fi
}

# Install assetfinder
install_assetfinder() {
  if [ ! -f "$HOME/go/bin/assetfinder" ]; then
    echo -e "${YELLOW}[+] Installing Assetfinder...${RESET}"
    go install -v github.com/tomnomnom/assetfinder@master
    echo -e "${GREEN}[+] Assetfinder installed${RESET}"
  else
    echo -e "${GREEN}[+] Assetfinder already installed${RESET}"
  fi
}

# Install httpx
install_httpx() {
  if [ ! -f "$HOME/go/bin/httpx" ]; then
    echo -e "${YELLOW}[+] Installing Httpx...${RESET}"
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    echo -e "${GREEN}[+] Httpx installed${RESET}"
  else
    echo -e "${GREEN}[+] Httpx already installed${RESET}"
  fi
}

# Install katana
install_katana() {
  if [ ! -f "$HOME/go/bin/katana" ]; then
    echo -e "${YELLOW}[+] Installing Katana...${RESET}"
    go install github.com/projectdiscovery/katana/cmd/katana@latest
    echo -e "${GREEN}[+] Katana installed${RESET}"
  else
    echo -e "${GREEN}[+] Katana already installed${RESET}"
  fi
}

# Install gowitness
install_gowitness() {
  if [ ! -f "$HOME/go/bin/gowitness" ]; then
    echo -e "${YELLOW}[+] Installing Gowitness...${RESET}"
    go install github.com/sensepost/gowitness@latest
    echo -e "${GREEN}[+] Gowitness installed${RESET}"
  else
    echo -e "${GREEN}[+] Gowitness already installed${RESET}"
  fi
}

# Install shosubgo
install_shosubgo() {
  if [ ! -f "$HOME/go/bin/shosubgo" ]; then
    echo -e "${YELLOW}[+] Installing Shosubgo...${RESET}"
    go install github.com/incogbyte/shosubgo@latest
    echo -e "${GREEN}[+] Shosubgo installed${RESET}"
  else
    echo -e "${GREEN}[+] Shosubgo already installed${RESET}"
  fi
}

# Install gf
install_gf() {
  if [ ! -f "$HOME/go/bin/gf" ]; then
    echo -e "${YELLOW}[+] Installing GF...${RESET}"
    go install github.com/tomnomnom/gf@latest
    echo -e "${GREEN}[+] GF installed${RESET}"
  else
    echo -e "${GREEN}[+] GF already installed${RESET}"
  fi
}

install_waymore() {
  if ! command -v waymore &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Waymore...${RESET}"
    pip install waymore &>/dev/null
    echo -e "${GREEN}[+] Waymore installed${RESET}"
  else
    echo -e "${GREEN}[+] Waymore already installed${RESET}"
  fi
}

install_xnlinkfinder() {
  if ! command -v xnLinkFinder &> /dev/null; then
    echo -e "${YELLOW}[+] Installing xnLinkFinder...${RESET}"
    pip install xnLinkFinder &>/dev/null
    echo -e "${GREEN}[+] xnLinkFinder installed${RESET}"
  else
    echo -e "${GREEN}[+] xnLinkFinder already installed${RESET}"
  fi
}

# Install shodan cli
install_shodan_cli() {
  if ! command -v shodan &> /dev/null; then
    echo -e "${YELLOW}[+] Installing Shodan CLI...${RESET}"
    apt install -y python3-shodan
    echo -e "${GREEN}[+] Shodan CLI installed${RESET}"
  else
    echo -e "${GREEN}[+] Shodan CLI already installed${RESET}"
  fi
}

setup_gf() {
  # Check if $HOME/.gf exists
  if [ -d "$HOME/.gf" ]; then
    echo -e "${GREEN}[+] GF already setup${RESET}"
    return
  fi
  echo -e "${YELLOW}[+] Setting up GF...${RESET}"
  git clone https://github.com/emadshanab/Gf-Patterns-Collection.git &>/dev/null
  cd Gf-Patterns-Collection || exit
  bash ./set-all.sh &>/dev/null
  cd ../
  rm -rf Gf-Patterns-Collection
  echo -e "${GREEN}[+] GF setup complete${RESET}"
}

# Setup shodan cli
setup_shodan_cli() {
  echo -e "${YELLOW}[+] Checking Shodan CLI initialization...${RESET}"

  # Check if Shodan is already initialized
  if shodan info &>/dev/null; then
    echo -e "${GREEN}[+] Shodan CLI is already initialized.${RESET}"
  else
    echo -e "${YELLOW}[+] Shodan CLI not initialized. Initializing now...${RESET}"
    shodan init $SHODAN_API_KEY &>/dev/null

    # Double check if initialization worked
    if shodan info &>/dev/null; then
      echo -e "${GREEN}[+] Shodan CLI successfully initialized.${RESET}"
    else
      echo -e "${RED}[-] Failed to initialize Shodan CLI. Please check your API key and try again.${RESET}"
    fi
  fi
}


# Install script dependencies
install_go_dependencies() {
  install_amass
  install_oam_tools
  install_assetfinder
  install_httpx
  install_katana
  install_gowitness
  install_shosubgo
  install_shodan_cli
  install_gf
}

# Setup python environment
setup_python_env() {
  # Check if the virtual environment exists
  if [ ! -d "$HOME/.venv" ]; then
    echo -e "${YELLOW}[+] Setting up Python environment...${RESET}"
    python3 -m venv "$HOME/.venv"
    echo -e "${GREEN}[+] Python environment setup${RESET}"
  else
    echo -e "${GREEN}[+] Python environment already setup${RESET}"
  fi
}

# Install python dependencies
install_python_dependencies() {
  source "$HOME/.venv/bin/activate"
  install_waymore
  install_xnlinkfinder
  deactivate
}

# Install docker
install_docker() {

  # Check if docker is already installed
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}[+] Docker already installed${RESET}"
    return
  fi

  echo -e "${YELLOW}[+] Installing Docker...${RESET}"

  # Add Docker's official GPG key:
  apt-get update -y
  apt-get install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y

  # Install Docker
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo -e "${GREEN}[+] Docker installed${RESET}"
}

# Setup postgres docker container
setup_postgres() {

  # Check if postgres docker container is already setup
  if docker ps -a | grep -q postgres; then
    echo -e "${GREEN}[+] Postgres docker container already setup${RESET}"
    return
  fi

  echo -e "${YELLOW}[+] Setting up Postgres docker container...${RESET}"
  cd ./postgres-custom || exit
  docker build -t postgres .
  docker run --name postgres -d -p 127.0.0.1:5432:5432 postgres
  echo -e "${GREEN}[+] Postgres docker container setup${RESET}"
  cd ../
}

download_amass_wordlists() {
  cd ./configs || exit

  # Check if the wordlists are already downloaded
  if [ -f ./wordlist_small.txt ] && [ -f ./wordlist_big.txt ]; then
    echo -e "${GREEN}[+] Amass wordlists already downloaded${RESET}"
    cd ../
    return
  fi

  echo -e "${YELLOW}[+] Downloading Amass wordlists...${RESET}"
  wget https://github.com/danielmiessler/SecLists/raw/refs/heads/master/Discovery/DNS/subdomains-top1million-20000.txt -O ./wordlist_small.txt &>/dev/null
  wget https://github.com/danielmiessler/SecLists/raw/refs/heads/master/Discovery/DNS/dns-Jhaddix.txt -O ./wordlist_big.txt &>/dev/null
  cd ../
  echo -e "${GREEN}[+] Amass wordlists downloaded${RESET}"
}

add_cron_job() {
  # Check if the crontab already contains the line
  if crontab -l -u "$SUDO_USER" | grep -Fxq "$CRON_JOB"; then
      echo -e "${YELLOW}[+] Crontab entry already exists.${RESET}"
  else
      echo -e "${YELLOW}[+] Adding crontab entry...${RESET}"
      # Add the entry since it doesn't exist
      crontab -l -u "$SUDO_USER" | { cat; echo "$CRON_JOB"; } | crontab -u "$SUDO_USER" -
      echo -e "${GREEN}[+] Crontab entry added.${RESET}"
  fi
}

add_go_path() {
  # Define the export lines
  GO_EXPORT_LINE1='export PATH=$PATH:/usr/local/go/bin'
  GO_EXPORT_LINE2='export PATH=$PATH:$HOME/go/bin'

  # Check if the first export line exists, if not, add it
  grep -Fxq "$GO_EXPORT_LINE1" "$HOME/.bashrc" || echo "$GO_EXPORT_LINE1" >> "$HOME/.bashrc"

  # Check if the second export line exists, if not, add it
  grep -Fxq "$GO_EXPORT_LINE2" "$HOME/.bashrc" || echo "$GO_EXPORT_LINE2" >> "$HOME/.bashrc"
}

# Main function
main() {
  export PATH="$PATH:/usr/local/go/bin"

  install_go
  install_python3
  install_chromium
  install_sqlite
  install_pip
  install_go_dependencies

  setup_gf

  setup_python_env
  install_python_dependencies

  setup_shodan_cli

  install_docker

  setup_postgres

  download_amass_wordlists

  add_cron_job

  # Give ownership of all files under $HOME to the user
  chown -R "$SUDO_USER":"$SUDO_USER" "$HOME"

  add_go_path

  mkdir -p "$HOME/recon/targets"

  echo -e "${GREEN}[+] Setup complete, source ~/.bashrc before proceeding${RESET}"
  echo -e "${GREEN}[+] Add targets with their respective download_csv.csv file under the targets/ directory${RESET}"
}

# Run the main function
main
