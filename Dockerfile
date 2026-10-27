# Imagem com Flutter + Android SDK (sem instalar nada no host)
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Evita avisos de "dubious ownership" com o volume montado do Windows
RUN git config --global --add safe.directory '*' \
    && git config --global --add safe.directory /sdks/flutter

ENV PUB_CACHE=/pub-cache
