// Gera o ícone do aplicativo (pino de mapa) como PNG, sem dependências.
// Uso: node scripts/gerar_icone.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const RAIZ = path.join(__dirname, '..');
const AMOSTRAS = 3; // supersampling AMOSTRAS x AMOSTRAS por pixel

// Cores do fundo (gradiente diagonal) e do pino.
const FUNDO_A = [0x00, 0x89, 0x7b];
const FUNDO_B = [0x00, 0x4d, 0x40];
const PINO = [255, 255, 255];

// Geometria do pino em coordenadas normalizadas (0..1).
const CX = 0.5;
const CY = 0.4;
const R = 0.2;
const PONTA = 0.84; // y da ponta
const R_FURO = 0.085;

function dentroDoPino(x, y) {
  if ((x - CX) ** 2 + (y - CY) ** 2 <= R * R) return true;
  // Triângulo tangente ao círculo até a ponta.
  const d = PONTA - CY;
  const cosT = R / d;
  const sinT = Math.sqrt(1 - cosT * cosT);
  const p1 = [CX - R * sinT, CY + R * cosT];
  const p2 = [CX + R * sinT, CY + R * cosT];
  return dentroDoTriangulo(x, y, [CX, PONTA], p1, p2);
}

function dentroDoTriangulo(x, y, a, b, c) {
  const s = (p, q, r) => (p[0] - r[0]) * (q[1] - r[1]) - (q[0] - r[0]) * (p[1] - r[1]);
  const p = [x, y];
  const d1 = s(p, a, b);
  const d2 = s(p, b, c);
  const d3 = s(p, c, a);
  const neg = d1 < 0 || d2 < 0 || d3 < 0;
  const pos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(neg && pos);
}

function dentroDoFuro(x, y) {
  return (x - CX) ** 2 + (y - CY) ** 2 <= R_FURO * R_FURO;
}

// Anel elíptico no chão, sugerindo o ponto marcado.
function dentroDoAnel(x, y) {
  const v = ((x - CX) / 0.2) ** 2 + ((y - 0.86) / 0.06) ** 2;
  return v <= 1 && v >= 0.62;
}

/**
 * Renderiza o ícone. [escala] reduz o desenho em torno do centro;
 * [comFundo] false deixa o fundo transparente (camada frontal do ícone adaptativo).
 */
function renderizar(tamanho, { escala = 1, comFundo = true } = {}) {
  const dados = Buffer.alloc(tamanho * tamanho * 4);
  const total = AMOSTRAS * AMOSTRAS;

  for (let py = 0; py < tamanho; py++) {
    for (let px = 0; px < tamanho; px++) {
      let pino = 0;
      let anel = 0;
      for (let sy = 0; sy < AMOSTRAS; sy++) {
        for (let sx = 0; sx < AMOSTRAS; sx++) {
          const nx = (px + (sx + 0.5) / AMOSTRAS) / tamanho;
          const ny = (py + (sy + 0.5) / AMOSTRAS) / tamanho;
          const x = (nx - 0.5) / escala + 0.5;
          const y = (ny - 0.5) / escala + 0.5;
          if (dentroDoPino(x, y) && !dentroDoFuro(x, y)) pino++;
          else if (dentroDoAnel(x, y)) anel++;
        }
      }
      const aPino = pino / total;
      const aAnel = (anel / total) * 0.65;

      // Cor do fundo no pixel (gradiente diagonal).
      const t = (px + py) / (2 * (tamanho - 1));
      const fundo = FUNDO_A.map((v, i) => v + (FUNDO_B[i] - v) * t);
      const aFundo = comFundo ? 1 : 0;

      // Composição: fundo, anel e pino (todas as camadas brancas sobre o fundo).
      const aBranco = aPino + aAnel * (1 - aPino);
      const aSaida = aBranco + aFundo * (1 - aBranco);
      const i = (py * tamanho + px) * 4;
      if (aSaida > 0) {
        for (let k = 0; k < 3; k++) {
          const c = (PINO[k] * aBranco + fundo[k] * aFundo * (1 - aBranco)) / aSaida;
          dados[i + k] = Math.round(c);
        }
      }
      dados[i + 3] = Math.round(aSaida * 255);
    }
  }
  return dados;
}

const TABELA_CRC = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = TABELA_CRC[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function bloco(tipo, dados) {
  const comprimento = Buffer.alloc(4);
  comprimento.writeUInt32BE(dados.length);
  const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(corpo));
  return Buffer.concat([comprimento, corpo, crc]);
}

// [semAlfa] gera RGB (sem canal alfa), como exigem os ícones do iOS.
function codificarPng(tamanho, rgba, semAlfa = false) {
  const canais = semAlfa ? 3 : 4;
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(tamanho, 0);
  ihdr.writeUInt32BE(tamanho, 4);
  ihdr[8] = 8; // 8 bits por canal
  ihdr[9] = semAlfa ? 2 : 6; // 2 = RGB, 6 = RGBA

  const linhas = Buffer.alloc(tamanho * (tamanho * canais + 1));
  for (let y = 0; y < tamanho; y++) {
    const destino = y * (tamanho * canais + 1);
    linhas[destino] = 0; // filtro "nenhum"
    if (!semAlfa) {
      rgba.copy(linhas, destino + 1, y * tamanho * 4, (y + 1) * tamanho * 4);
      continue;
    }
    for (let x = 0; x < tamanho; x++) {
      const origem = (y * tamanho + x) * 4;
      rgba.copy(linhas, destino + 1 + x * 3, origem, origem + 3);
    }
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    bloco('IHDR', ihdr),
    bloco('IDAT', zlib.deflateSync(linhas, { level: 9 })),
    bloco('IEND', Buffer.alloc(0)),
  ]);
}

function gravar(relativo, tamanho, opcoes = {}) {
  const { semAlfa = false, ...desenho } = opcoes;
  const destino = path.join(RAIZ, relativo);
  fs.mkdirSync(path.dirname(destino), { recursive: true });
  fs.writeFileSync(
    destino,
    codificarPng(tamanho, renderizar(tamanho, desenho), semAlfa),
  );
  console.log(`gerado ${relativo} (${tamanho}x${tamanho})`);
}

function gravarTexto(relativo, conteudo) {
  const destino = path.join(RAIZ, relativo);
  fs.mkdirSync(path.dirname(destino), { recursive: true });
  fs.writeFileSync(destino, conteudo);
  console.log(`gerado ${relativo}`);
}

const RES = 'android/app/src/main/res';
const COR_FUNDO_ADAPTATIVO = '#00695C';

// Imagem original.
gravar('assets/icons/localizacoes.png', 1024);

// Ícones legados (Android < 8), um por densidade.
const DENSIDADES = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
for (const [densidade, tamanho] of Object.entries(DENSIDADES)) {
  gravar(`${RES}/mipmap-${densidade}/ic_localizacoes.png`, tamanho);
}

// Camada frontal do ícone adaptativo (108dp x 4): desenho reduzido para caber
// na zona segura e fundo transparente.
gravar(`${RES}/drawable-nodpi/icone_localizacoes.png`, 432, {
  escala: 0.68,
  comFundo: false,
});

gravarTexto(
  `${RES}/mipmap-anydpi-v26/ic_localizacoes.xml`,
  `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/icone_localizacoes_fundo"/>
    <foreground android:drawable="@drawable/icone_localizacoes"/>
</adaptive-icon>
`,
);

gravarTexto(
  `${RES}/values/icone_localizacoes.xml`,
  `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="icone_localizacoes_fundo">${COR_FUNDO_ADAPTATIVO}</color>
</resources>
`,
);

// Conjunto de ícones do iOS, conforme o Contents.json do AppIcon.
const CONJUNTO_IOS = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const contents = JSON.parse(
  fs.readFileSync(path.join(RAIZ, CONJUNTO_IOS, 'Contents.json'), 'utf8'),
);
for (const imagem of contents.images) {
  const lado = Math.round(parseFloat(imagem.size) * parseInt(imagem.scale, 10));
  gravar(`${CONJUNTO_IOS}/${imagem.filename}`, lado, { semAlfa: true });
}
