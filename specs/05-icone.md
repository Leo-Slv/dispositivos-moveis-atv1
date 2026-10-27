# Spec 05 - Ícone do aplicativo

## Requisitos

- Criar um ícone próprio, relacionado à proposta (localização).
- Substituir o ícone padrão do Flutter.
- Manter a imagem original em `assets/icons/localizacoes.png`.
- Conferir o ícone na tela inicial e na lista de aplicativos após instalar.

## Android (`android/app/src/main/`)

- `AndroidManifest.xml` referencia o ícone.
- `res/drawable-nodpi/icone_localizacoes.png`: imagem do ícone adaptativo.
- `res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_localizacoes.png`.
- `res/mipmap-anydpi-v26/ic_localizacoes.xml`: definição do ícone adaptativo.
- `res/values/icone_localizacoes.xml`: cor de fundo do ícone.

## iOS (se escolhido)

- Adaptar os recursos do ícone às exigências da plataforma.

## Critérios de aceite

- [ ] Nenhum ícone padrão do Flutter restante.
- [ ] Todas as densidades presentes.
- [ ] Ícone adaptativo renderiza corretamente.
