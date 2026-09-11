readme_content = """# 📱 Mobile - Sistema de Gestão e Correção de Provas

Aplicativo desenvolvido em **Flutter** com o objetivo de auxiliar professores no gerenciamento de avaliações, oferecendo recursos desde a criação e banco de questões até a correção simulada por QR Code e geração de relatórios de desempenho.

---

## 🎯 Objetivo do Projeto
Fornecer uma ferramenta móvel ágil e intuitiva para o fluxo de avaliação escolar (MVP), permitindo o cadastro de questões, montagem dinâmica de provas, simulação de leitura de gabaritos e acompanhamento de notas de forma descentralizada.

---

## 🛠️ Tecnologias Utilizadas
* **[Flutter](https://flutter.dev/)** (Versão SDK recente)
* **Dart** (Linguagem de programação)
* **Visual Studio / VS Code** (Ambiente de Desenvolvimento)
* **Git & GitHub** (Controle de versão e gestão de issues/projetos)

---

## 🏗️ Arquitetura e Estrutura de Pastas
O projeto segue uma organização limpa dividida por responsabilidades dentro da pasta `lib/`:

```text
lib/
├── mocks/       # Dados estáticos simulados para testes e prototipagem
├── models/      # Classes de domínio (Prova, Questao, Alternativa, Aluno)
├── screens/     # Telas da interface gráfica (UI) e fluxos de navegação
└── main.dart    # Ponto de entrada da aplicação e configuração de rotas
