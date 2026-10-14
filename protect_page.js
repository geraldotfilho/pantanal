#!/usr/bin/env node
// protect_page.js - Mesmo formato do protect.ps1 (AES-256-CBC + HMAC-SHA256, PBKDF2-SHA256 600.000 iteracoes),
// para rodar com Node em qualquer sistema e em qualquer pasta de roteiro.
// Uso: node protect_page.js [pasta]   (padrao: pasta atual do repo)
// Le <pasta>/index_original.html, <pasta>/login_template.html e <pasta>/.password
// e gera <pasta>/index.html.

const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const dir = path.resolve(__dirname, process.argv[2] || '.');
const srcPath = path.join(dir, 'index_original.html');
const outPath = path.join(dir, 'index.html');
const tmplPath = path.join(dir, 'login_template.html');
const pwdFile = path.join(dir, '.password');

for (const f of [srcPath, tmplPath, pwdFile]) {
  if (!fs.existsSync(f)) { console.error('ERRO: arquivo nao encontrado: ' + f); process.exit(1); }
}
const password = fs.readFileSync(pwdFile, 'utf8').replace(/^﻿/, '').trim();
if (!password) { console.error('ERRO: senha vazia em ' + pwdFile); process.exit(1); }

const plaintext = fs.readFileSync(srcPath);
const salt = crypto.randomBytes(32);
const iv = crypto.randomBytes(16);
const derived = crypto.pbkdf2Sync(password, salt, 600000, 64, 'sha256');
const aesKey = derived.subarray(0, 32);
const hmacKey = derived.subarray(32, 64);

const cipher = crypto.createCipheriv('aes-256-cbc', aesKey, iv);
const ct = Buffer.concat([cipher.update(plaintext), cipher.final()]);
const mac = crypto.createHmac('sha256', hmacKey).update(Buffer.concat([salt, iv, ct])).digest();

const payload = JSON.stringify({ salt: salt.toString('hex'), iv: iv.toString('hex'), ct: ct.toString('base64'), mac: mac.toString('hex') });
const html = fs.readFileSync(tmplPath, 'utf8').replace('___PAYLOAD___', () => payload);
fs.writeFileSync(outPath, html, 'utf8');

console.log('OK ' + path.relative(__dirname, outPath) + ' protegido gerado (' + Math.round(fs.statSync(outPath).size / 1024) + ' KB)');
