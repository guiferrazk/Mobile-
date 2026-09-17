<p align="center">
  <h1 align="center">📱 Mobile — Sistema de Gestão e Correção de Avaliações</h1>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Status-Em_Desenvolvimento_(N1)-yellow?style=for-the-badge" alt="Status">
</p>

---

## 📖 Sobre o Projeto

O **Mobile** é um aplicativo desenvolvido em **Flutter/Dart** voltado para o ecossistema educacional. O sistema auxilia professores no ciclo completo de avaliações: desde a gestão de um banco de questões e a montagem dinâmica de provas, até a correção simulada por QR Code e a geração de relatórios de desempenho[cite: 1]. 

* **Objetivo principal:** Automatizar a correção de provas objetivas. O professor aplica a prova, recolhe a folha de resposta e o aplicativo faz a leitura (via QR Code e marcações), gerando a nota automaticamente para otimizar o tempo e permitir uma devolutiva ágil aos alunos[cite: 1].

---

## 📋 Requisitos do Sistema (Escopo N1)

### Requisitos Funcionais (RF)
* **RF01:** Cadastrar questões em um banco de questões[cite: 1].
* **RF02:** Montar/gerar prova a partir do banco de questões[cite: 1].
* **RF03:** Embaralhar ordem de questões e alternativas entre as provas (variação por aluno)[cite: 1].
* **RF04:** Gerar folha de resposta com QR Code identificador[cite: 1].
* **RF05:** Ler o gabarito via QR Code[cite: 1].
* **RF06:** Ler a folha de resposta do aluno e reconhecer as alternativas marcadas[cite: 1].
* **RF07:** Calcular e exibir a nota automaticamente[cite: 1].
* **RF08:** Listar provas já corrigidas[cite: 1].
* **RF09:** Gerar estatística por questão (qual alternativa foi mais assinalada)[cite: 1].
* **RF10:** Gerar relatório de notas exportável em planilha (Excel)[cite: 1].
* **RF11:** Importar lista de alunos[cite: 1].
* **RF12:** Gerar prova individualizada, identificável por aluno pela folha de resposta[cite: 1].

### Requisitos Não Funcionais (RNF) e Limites
* **RNF01:** Plataforma mobile (aplicativo), desenvolvido em Flutter/Dart[cite: 1].
* **RNF02:** Interface minimalista, com poucos elementos por tela; prioridade em ser amigável e fácil de usar[cite: 1].
* **RNF03:** Construção lógica da navegação com clareza de fluxo[cite: 1].
* **RNF04:** Desempenho na correção: referência de corrigir uma turma de ~50 alunos em cerca de 30 minutos[cite: 1].
* **RNF05:** Formato de saída dos dados preferencialmente em planilha (Excel)[cite: 1].
* **RNF06:** Nesta etapa (N1), telas navegáveis com dados fictícios (`mock`), sem banco de dados real[cite: 1].
* **RNF07:** Integração com banco de dados real (Firebase Firestore) prevista apenas a partir da N2[cite: 1].
* **RNF08:** Limite de escopo: a geração de prova em formato editável (`.doc`) e ajuste de layout foram citados como sugestão secundária[cite: 1].

---

## 🏛️ Arquitetura e Estrutura de Pastas

```text
lib/
├── mocks/       # Dados estáticos simulados para testes rápidos e validação de UI
├── models/      # Classes de domínio da aplicação (Prova, Questao, Alternativa, Aluno, etc.)
├── screens/     # Telas e fluxos da interface gráfica (UI)
│   ├── banco_questoes.dart
│   ├── corrigir_prova.dart
│   ├── criar_prova.dart
│   ├── home_screen.dart
│   └── login_screen.dart
├── widgets/     # Componentes visuais reaproveitáveis
└── main.dart    # Ponto de entrada, configuração de tema e mapeamento de rotas