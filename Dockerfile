# Imagem com Flutter + Android SDK (sem instalar nada no host)
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Evita avisos de "dubious ownership" com o volume montado do Windows
RUN git config --global --add safe.directory '*' \
    && git config --global --add safe.directory /sdks/flutter

# Componentes do Android SDK exigidos pelo build (embutidos na imagem para não
# serem baixados a cada execução).
RUN sdkmanager "platforms;android-35" "ndk;28.2.13676358" "cmake;3.22.1"

ENV PUB_CACHE=/pub-cache
