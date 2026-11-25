// Atribui a um professor todos os documentos que ainda não têm professorId.
//
// Uso (na pasta tool/):
//   npm install
//   node migrar_professor.mjs lucas.barra@gmail.com            # só mostra o que faria
//   node migrar_professor.mjs lucas.barra@gmail.com --aplicar  # grava de verdade
//
// Precisa da chave de conta de serviço do projeto (Console do Firebase >
// Configurações do projeto > Contas de serviço > Gerar nova chave privada),
// salva como tool/chave-servico.json. Esse arquivo é secreto e não vai
// para o git.
//
// Só mexe em documentos SEM professorId: rodar de novo não altera o que já
// foi migrado nem o que pertence a outro professor.

import { readFileSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const COLECOES = ['alunos', 'turmas', 'materias', 'questoes', 'provas', 'resultados'];

const email = process.argv[2];
const aplicar = process.argv.includes('--aplicar');

if (!email || email.startsWith('--')) {
  console.error('Informe o e-mail do professor. Ex.: node migrar_professor.mjs professor@email.com');
  process.exit(1);
}

const chave = JSON.parse(readFileSync(new URL('./chave-servico.json', import.meta.url)));
initializeApp({ credential: cert(chave) });

const usuario = await getAuth().getUserByEmail(email.trim());
const uid = usuario.uid;
console.log(`Professor: ${usuario.email} (uid ${uid})`);
console.log(aplicar ? 'MODO: GRAVANDO' : 'MODO: simulação (use --aplicar para gravar)');

const db = getFirestore();
let total = 0;

for (const nome of COLECOES) {
  const docs = (await db.collection(nome).get()).docs;
  const semDono = docs.filter((doc) => doc.get('professorId') === undefined);
  console.log(`${nome}: ${docs.length} documentos, ${semDono.length} sem professorId`);

  if (aplicar) {
    // O Firestore aceita no máximo 500 operações por lote.
    for (let i = 0; i < semDono.length; i += 400) {
      const lote = db.batch();
      for (const doc of semDono.slice(i, i + 400)) {
        lote.update(doc.ref, { professorId: uid });
      }
      await lote.commit();
    }
  }
  total += semDono.length;
}

console.log(aplicar ? `Migrados: ${total} documentos.` : `Seriam migrados: ${total} documentos.`);
