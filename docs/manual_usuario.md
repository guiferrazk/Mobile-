
# Manual do Usuário — Mobile: Corretor de Provas

**Equipe:** Codex Ludus  
**Disciplina:** Desenvolvimento de Dispositivos Móveis  
**Entrega:** N3 — Novembro de 2026

---

## 1. Apresentação

O Mobile — Corretor de Provas é um aplicativo desenvolvido em Flutter e Dart, com integração ao Firebase.

Seu objetivo é auxiliar professores na organização de questões, elaboração de provas, gerenciamento de alunos e conferência de respostas.

Este manual apresenta as funcionalidades disponíveis e o fluxo de utilização desenvolvido até a N3.

## 2. Acesso ao sistema

1. Abra o aplicativo.
2. Na tela de login, informe seu e-mail e sua senha.
3. Caso ainda não tenha uma conta, utilize a opção de cadastro.
4. Após a autenticação, acesse o menu principal.

O aplicativo utiliza Firebase Authentication para gerenciar o acesso.

## 3. Banco de questões

Para preparar uma avaliação:

1. Acesse o Banco de Questões.
2. Cadastre o enunciado da questão.
3. Informe as alternativas disponíveis.
4. Indique qual alternativa é a correta.
5. Salve a questão.

As questões cadastradas são armazenadas no Cloud Firestore e podem ser utilizadas na montagem de provas.

## 4. Criar uma prova

1. No menu principal, acesse a opção de criação de provas.
2. Informe o título da avaliação.
3. Selecione as questões desejadas no banco de questões.
4. Confira as questões selecionadas.
5. Salve a prova.

A prova poderá ser consultada posteriormente.

## 5. Consultar e editar provas

1. Acesse a tela de consulta de provas.
2. Localize a avaliação desejada.
3. Utilize a opção de edição quando precisar modificar o título ou as questões.
4. Salve as alterações.

A tela também permite acessar a geração de variações individuais.

## 6. Gerar uma variação individual

Esta funcionalidade foi implementada na N3.

1. Acesse Consultar Provas.
2. Escolha a prova desejada.
3. Clique na opção de gerar variação.
4. Selecione um aluno cadastrado.
5. Clique no botão de gerar ou recuperar a variação.
6. Confira a ordem das questões e das alternativas apresentada na tela.

O aplicativo embaralha as questões e alternativas e salva a versão individual no Firestore.

**Importante:** se a variação já tiver sido gerada para o mesmo aluno e a mesma prova, o aplicativo recuperará a versão armazenada, preservando a ordem anterior.

## 7. Corrigir uma prova

Na tela Corrigir Prova, é necessário identificar primeiro a avaliação e depois o aluno.

### 7.1 Identificar a prova

O professor pode utilizar uma das opções:

- Ler o QR Code do gabarito.
- Selecionar a prova diretamente na lista de avaliações cadastradas.

A segunda opção permite identificar a prova sem consultar códigos no Console do Firebase.

### 7.2 Identificar o aluno

Depois de identificar a prova, o professor poderá:

- Ler o código da folha do aluno.
- Informar a matrícula pelo campo de digitação.
- Escolher o aluno na lista, caso a leitura não esteja disponível.

### 7.3 Recuperar a variação individual

Após identificar a prova e o aluno, o aplicativo consulta o Firestore.

Se houver uma variação salva, as questões e alternativas serão apresentadas na ordem atribuída ao aluno.

Se não houver variação cadastrada, será necessário gerá-la antes de realizar essa conferência.

## 8. Conferência manual das respostas

1. Abra a versão individual recuperada.
2. Observe as questões na ordem apresentada.
3. Selecione a alternativa marcada pelo aluno em cada questão.
4. Clique em Conferir respostas.
5. Verifique a quantidade de acertos e a nota apresentada.

A conferência considera a correspondência entre as alternativas embaralhadas e os índices originais armazenados.

**Atenção:** nesta implementação, as respostas são informadas manualmente e o resultado da conferência não é salvo no Firestore.

## 9. Cadastro e consulta de alunos

O aplicativo possui funcionalidades de cadastro e consulta de alunos.

Também permite importar informações por planilhas CSV ou XLSX, com validação dos dados antes do armazenamento.

## 10. Problemas comuns

### A prova não aparece na lista

Verifique se ela foi cadastrada e salva corretamente.

### O aluno não aparece

Verifique se o aluno está cadastrado e se o nome ou a matrícula foram informados corretamente na busca.

### A variação não foi encontrada

Acesse a consulta de provas, selecione a avaliação e gere a variação para o aluno desejado.

### A câmera não funciona

Verifique as permissões do dispositivo ou navegador.

Quando disponível, utilize a seleção manual da prova ou do aluno para continuar.

### Erro de conexão

Verifique a conexão com a internet e tente novamente.

## 11. Limitações da entrega

A geração, o armazenamento e a recuperação das variações individuais foram implementados e testados na N3.

A conferência das respostas disponível nesta implementação é manual.

O reconhecimento automático das alternativas marcadas na folha, a persistência do resultado da conferência e a integração completa dos demais fluxos dependem de desenvolvimento e validação adicionais pela equipe.

---

**Projeto acadêmico — Codex Ludus**
