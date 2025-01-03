FROM postgres:latest

# Copy the custom initialization script into the container
COPY ./init-db.sh /docker-entrypoint-initdb.d/init-db.sh

# Set default user and password for PostgreSQL
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password

EXPOSE 5432

# Run the PostgreSQL server
CMD ["postgres"]