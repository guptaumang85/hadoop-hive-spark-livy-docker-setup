FROM postgres

User root
ENV POSTGRES_PASSWORD mysecret

COPY conf/init-hive-db.sql /docker-entrypoint-initdb.d/init-user-db.sql
