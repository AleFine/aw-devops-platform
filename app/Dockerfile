FROM php:8.3-apache-bookworm

RUN apt-get update \
	&& apt-get -y upgrade \
	&& sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
	&& sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf \
	&& useradd -r -u 10001 -d /var/www -s /usr/sbin/nologin appuser \
	&& chown -R appuser:appuser /var/www/html \
	&& rm -rf /var/lib/apt/lists/*

COPY index.php /var/www/html/

EXPOSE 8080

USER appuser

CMD ["apache2-foreground"]
