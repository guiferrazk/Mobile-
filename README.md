<p align="center">
  <h1 align="center">📱 Mobile — Sistema de Gestão e Correção de Avaliações</h1>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow?style=for-the-badge" alt="Status">
</p>

---

## 📖 Sobre o Projeto

O **Mobile** é um aplicativo desenvolvido em **Flutter** voltado para o ecossistema educacional. O sistema auxilia professores no ciclo completo de avaliações: desde a gestão de um banco de questões e a montagem dinâmica de provas, até a correção simulada por QR Code e a geração de relatórios de desempenho.

---

## 🏛️ Arquitetura e Estrutura de Pastas

```text
lib/
├── mocks/       # Dados estáticos simulados para testes rápidos e validação de UI
├── models/      # Classes de domínio da aplicação (Prova, Questao, Alternativa, Aluno)
├── screens/     # Telas e fluxos da interface gráfica (UI)
└── main.dart    # Ponto de entrada, configuração de tema e mapeamento de rotas