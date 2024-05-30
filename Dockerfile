# Utilizar una imagen base oficial de Debian
FROM debian:latest

# Establecer las variables de entorno
ENV NAGIOS_VERSION=4.4.10
ENV NAGIOS_PLUGINS_VERSION=2.3.3

# Instalar las dependencias necesarias
RUN apt-get update && apt-get install -y \
    apache2 \
    build-essential \
    libgd-dev \
    libjpeg-dev \
    libpng-dev \
    libperl-dev \
    libssl-dev \
    wget \
    unzip \
    bc \
    gawk \
    dc \
    dnsutils \
    mailutils \
    postfix \
    autoconf \
    automake \
    libtool \
    bsd-mailx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear un usuario y grupo para Nagios
RUN useradd nagios \
    && groupadd nagcmd \
    && usermod -aG nagcmd nagios \
    && usermod -aG nagcmd www-data

# Descargar, compilar e instalar Nagios Core
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NAGIOS_VERSION}.tar.gz \
    && tar -zxvf nagios-${NAGIOS_VERSION}.tar.gz \
    && cd nagios-${NAGIOS_VERSION} \
    && ./configure --with-command-group=nagcmd \
    && make all \
    && make install \
    && make install-commandmode \
    && make install-init \
    && make install-config \
    && make install-webconf \
    && htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin \
    && cd .. \
    && rm -rf nagios-${NAGIOS_VERSION} nagios-${NAGIOS_VERSION}.tar.gz

# Descargar, compilar e instalar Nagios Plugins
RUN wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz \
    && tar -zxvf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz \
    && cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} \
    && ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl \
    && make \
    && make install \
    && cd .. \
    && rm -rf nagios-plugins-${NAGIOS_PLUGINS_VERSION} nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz

# Habilitar los servicios de Apache y Nagios
RUN ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios \
    && a2enmod rewrite \
    && a2enmod cgi

# Exponer el puerto 80 para acceder a la interfaz web de Nagios
EXPOSE 80

# Copiar el script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Configurar el punto de entrada
ENTRYPOINT ["/start.sh"]

