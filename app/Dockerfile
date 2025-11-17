FROM php:8.3-apache-bookworm

RUN apt-get update \
	&& apt-get -y upgrade \
	&& rm -rf /var/lib/apt/lists/*
COPY index.php /var/www/html/
EXPOSE 80
