import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/materia_model.dart';
import 'package:mobile/models/questao_model.dart';

final List<Materia> listaMateria = <Materia>[
  Materia(
    id: '1',
    descricao: 'Direito Constitucional',
    questoes: <Questao>[
      Questao(
        id: 'dc1',
        enunciado: 'Qual é a norma máxima do ordenamento jurídico brasileiro, à qual todas as demais devem se submeter?',
        alternativas: [
          Alternativa(texto: 'O Código Civil', isCorreta: false),
          Alternativa(texto: 'A Constituição Federal', isCorreta: true),
          Alternativa(texto: 'A Lei de Introdução às Normas do Direito Brasileiro', isCorreta: false),
          Alternativa(texto: 'O Código Penal', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc2',
        enunciado: 'Segundo a Constituição Federal de 1988, quais são os Poderes da União, independentes e harmônicos entre si?',
        alternativas: [
          Alternativa(texto: 'Executivo, Legislativo e Judiciário', isCorreta: true),
          Alternativa(texto: 'Federal, Estadual e Municipal', isCorreta: false),
          Alternativa(texto: 'Civil, Penal e Administrativo', isCorreta: false),
          Alternativa(texto: 'Executivo, Ministério Público e Judiciário', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc3',
        enunciado: 'O que caracteriza uma cláusula pétrea na Constituição Federal?',
        alternativas: [
          Alternativa(texto: 'Uma norma que pode ser alterada por lei ordinária', isCorreta: false),
          Alternativa(texto: 'Uma matéria que não pode ser abolida nem mesmo por emenda constitucional', isCorreta: true),
          Alternativa(texto: 'Um dispositivo aplicável apenas em estado de sítio', isCorreta: false),
          Alternativa(texto: 'Uma norma de eficácia limitada', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc4',
        enunciado: 'Qual é o quórum exigido para a aprovação de uma Emenda Constitucional?',
        alternativas: [
          Alternativa(texto: 'Maioria simples em turno único', isCorreta: false),
          Alternativa(texto: 'Maioria absoluta em turno único', isCorreta: false),
          Alternativa(texto: 'Três quintos dos votos, em dois turnos, em cada Casa do Congresso', isCorreta: true),
          Alternativa(texto: 'Dois terços dos votos, em turno único', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc5',
        enunciado: 'Qual remédio constitucional é destinado a proteger direito líquido e certo não amparado por habeas corpus ou habeas data?',
        alternativas: [
          Alternativa(texto: 'Mandado de injunção', isCorreta: false),
          Alternativa(texto: 'Ação popular', isCorreta: false),
          Alternativa(texto: 'Mandado de segurança', isCorreta: true),
          Alternativa(texto: 'Habeas corpus', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc6',
        enunciado: 'O habeas corpus é o remédio constitucional destinado a proteger qual direito?',
        alternativas: [
          Alternativa(texto: 'Direito de propriedade', isCorreta: false),
          Alternativa(texto: 'Liberdade de locomoção', isCorreta: true),
          Alternativa(texto: 'Direito à informação pessoal', isCorreta: false),
          Alternativa(texto: 'Direito de petição', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc7',
        enunciado: 'Segundo a Constituição Federal, qual é a forma de governo adotada pelo Brasil?',
        alternativas: [
          Alternativa(texto: 'Monarquia constitucional', isCorreta: false),
          Alternativa(texto: 'República', isCorreta: true),
          Alternativa(texto: 'Confederação', isCorreta: false),
          Alternativa(texto: 'Principado', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc8',
        enunciado: 'Qual instrumento é utilizado para questionar, de forma abstrata, a constitucionalidade de uma lei perante o STF?',
        alternativas: [
          Alternativa(texto: 'Recurso Extraordinário', isCorreta: false),
          Alternativa(texto: 'Ação Direta de Inconstitucionalidade (ADI)', isCorreta: true),
          Alternativa(texto: 'Mandado de Segurança Coletivo', isCorreta: false),
          Alternativa(texto: 'Reclamação Constitucional', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc9',
        enunciado: 'Em qual título da Constituição Federal de 1988 estão previstos os Direitos e Garantias Fundamentais?',
        alternativas: [
          Alternativa(texto: 'Título I', isCorreta: false),
          Alternativa(texto: 'Título II', isCorreta: true),
          Alternativa(texto: 'Título IV', isCorreta: false),
          Alternativa(texto: 'Título VIII', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dc10',
        enunciado: 'O princípio segundo o qual ninguém será processado nem sentenciado senão pela autoridade competente é conhecido como:',
        alternativas: [
          Alternativa(texto: 'Princípio da ampla defesa', isCorreta: false),
          Alternativa(texto: 'Princípio do juiz natural', isCorreta: true),
          Alternativa(texto: 'Princípio da publicidade', isCorreta: false),
          Alternativa(texto: 'Princípio da legalidade', isCorreta: false),
        ],
      ),
    ],
  ),
  Materia(
    id: '2',
    descricao: 'Direito Civil',
    questoes: <Questao>[
      Questao(
        id: 'dv1',
        enunciado: 'Segundo o Código Civil, em que idade a pessoa natural adquire a capacidade civil plena, via de regra?',
        alternativas: [
          Alternativa(texto: '16 anos', isCorreta: false),
          Alternativa(texto: '18 anos', isCorreta: true),
          Alternativa(texto: '21 anos', isCorreta: false),
          Alternativa(texto: '14 anos', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv2',
        enunciado: 'Qual instituto extingue a obrigação por meio do cumprimento voluntário da prestação devida?',
        alternativas: [
          Alternativa(texto: 'Novação', isCorreta: false),
          Alternativa(texto: 'Pagamento (adimplemento)', isCorreta: true),
          Alternativa(texto: 'Remissão', isCorreta: false),
          Alternativa(texto: 'Compensação', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv3',
        enunciado: 'O contrato de compra e venda é classicamente classificado como:',
        alternativas: [
          Alternativa(texto: 'Unilateral, gratuito e real', isCorreta: false),
          Alternativa(texto: 'Bilateral, oneroso e consensual', isCorreta: true),
          Alternativa(texto: 'Solene e aleatório', isCorreta: false),
          Alternativa(texto: 'Personalíssimo e gratuito', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv4',
        enunciado: 'Segundo o Código Civil, o que caracteriza a posse?',
        alternativas: [
          Alternativa(texto: 'O exercício de fato, pleno ou não, de algum dos poderes inerentes à propriedade', isCorreta: true),
          Alternativa(texto: 'O registro do imóvel em cartório', isCorreta: false),
          Alternativa(texto: 'A ausência de qualquer relação com a coisa', isCorreta: false),
          Alternativa(texto: 'A propriedade plena e definitiva do bem', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv5',
        enunciado: 'Qual é o prazo prescricional geral aplicável à pretensão de reparação civil no Código Civil?',
        alternativas: [
          Alternativa(texto: '1 ano', isCorreta: false),
          Alternativa(texto: '3 anos', isCorreta: true),
          Alternativa(texto: '5 anos', isCorreta: false),
          Alternativa(texto: '10 anos', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv6',
        enunciado: 'Qual instituto é utilizado para dissolver a sociedade conjugal e o vínculo matrimonial?',
        alternativas: [
          Alternativa(texto: 'Separação de corpos', isCorreta: false),
          Alternativa(texto: 'Divórcio', isCorreta: true),
          Alternativa(texto: 'Anulação de casamento', isCorreta: false),
          Alternativa(texto: 'União estável', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv7',
        enunciado: 'O que é usucapião?',
        alternativas: [
          Alternativa(texto: 'Forma de aquisição da propriedade pela posse prolongada, com os requisitos legais', isCorreta: true),
          Alternativa(texto: 'Forma de extinção da propriedade por abandono', isCorreta: false),
          Alternativa(texto: 'Modalidade de doação entre vivos', isCorreta: false),
          Alternativa(texto: 'Instrumento de transferência de dívidas', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv8',
        enunciado: 'A sucessão legítima ocorre principalmente quando:',
        alternativas: [
          Alternativa(texto: 'O falecido deixou testamento válido dispondo de todos os bens', isCorreta: false),
          Alternativa(texto: 'Não há testamento, ou este não abrange todos os bens', isCorreta: true),
          Alternativa(texto: 'Os herdeiros renunciam à herança', isCorreta: false),
          Alternativa(texto: 'O inventário é feito extrajudicialmente', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv9',
        enunciado: 'Quando a pessoa natural adquire personalidade jurídica, segundo o Código Civil?',
        alternativas: [
          Alternativa(texto: 'A partir da concepção, sem exceções', isCorreta: false),
          Alternativa(texto: 'A partir do nascimento com vida', isCorreta: true),
          Alternativa(texto: 'A partir do registro de nascimento em cartório', isCorreta: false),
          Alternativa(texto: 'Somente ao completar a maioridade', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dv10',
        enunciado: 'O contrato de locação de imóveis urbanos é regulado principalmente por qual lei?',
        alternativas: [
          Alternativa(texto: 'Código de Defesa do Consumidor', isCorreta: false),
          Alternativa(texto: 'Lei do Inquilinato (Lei nº 8.245/1991)', isCorreta: true),
          Alternativa(texto: 'Estatuto da Cidade', isCorreta: false),
          Alternativa(texto: 'Lei de Registros Públicos', isCorreta: false),
        ],
      ),
    ],
  ),
  Materia(
    id: '3',
    descricao: 'Direito Penal',
    questoes: <Questao>[
      Questao(
        id: 'dp1',
        enunciado: 'Qual princípio estabelece que não há crime sem lei anterior que o defina, nem pena sem prévia cominação legal?',
        alternativas: [
          Alternativa(texto: 'Princípio da culpabilidade', isCorreta: false),
          Alternativa(texto: 'Princípio da legalidade (nullum crimen, nulla poena sine lege)', isCorreta: true),
          Alternativa(texto: 'Princípio da insignificância', isCorreta: false),
          Alternativa(texto: 'Princípio da individualização da pena', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp2',
        enunciado: 'O que caracteriza o dolo, segundo o Código Penal?',
        alternativas: [
          Alternativa(texto: 'A previsibilidade objetiva do resultado', isCorreta: false),
          Alternativa(texto: 'A vontade livre e consciente de praticar a conduta descrita no tipo penal', isCorreta: true),
          Alternativa(texto: 'A quebra de um dever de cuidado objetivo', isCorreta: false),
          Alternativa(texto: 'A ausência de intenção de causar o resultado', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp3',
        enunciado: 'Qual é a principal diferença entre crime doloso e crime culposo?',
        alternativas: [
          Alternativa(texto: 'O crime culposo sempre resulta em pena maior', isCorreta: false),
          Alternativa(texto: 'O crime culposo decorre de negligência, imprudência ou imperícia, sem vontade de causar o resultado', isCorreta: true),
          Alternativa(texto: 'O crime doloso não admite tentativa', isCorreta: false),
          Alternativa(texto: 'Não há diferença prática entre eles', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp4',
        enunciado: 'O que caracteriza a legítima defesa, segundo o Código Penal?',
        alternativas: [
          Alternativa(texto: 'Repelir injusta agressão, atual ou iminente, a direito próprio ou alheio, usando moderadamente os meios necessários', isCorreta: true),
          Alternativa(texto: 'Praticar qualquer ato de vingança após uma agressão sofrida', isCorreta: false),
          Alternativa(texto: 'Agir em cumprimento de dever legal, independentemente de agressão', isCorreta: false),
          Alternativa(texto: 'Utilizar força desproporcional para evitar um dano patrimonial', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp5',
        enunciado: 'A prescrição penal tem como principal efeito extinguir:',
        alternativas: [
          Alternativa(texto: 'A tipicidade da conduta', isCorreta: false),
          Alternativa(texto: 'A punibilidade do agente', isCorreta: true),
          Alternativa(texto: 'A ilicitude do fato', isCorreta: false),
          Alternativa(texto: 'A competência do juízo', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp6',
        enunciado: 'Segundo o Código Penal, o que é a tentativa de crime?',
        alternativas: [
          Alternativa(texto: 'Quando o agente desiste voluntariamente de prosseguir na execução', isCorreta: false),
          Alternativa(texto: 'Quando, iniciada a execução, o crime não se consuma por circunstâncias alheias à vontade do agente', isCorreta: true),
          Alternativa(texto: 'Quando o agente apenas cogita a prática do crime, sem iniciar a execução', isCorreta: false),
          Alternativa(texto: 'Quando o crime se consuma plenamente', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp7',
        enunciado: 'Qual é a principal diferença entre os crimes de furto e roubo?',
        alternativas: [
          Alternativa(texto: 'Não há diferença, são sinônimos no Código Penal', isCorreta: false),
          Alternativa(texto: 'O roubo é praticado mediante violência ou grave ameaça à pessoa, o que não ocorre no furto', isCorreta: true),
          Alternativa(texto: 'O furto só pode ser cometido contra pessoa jurídica', isCorreta: false),
          Alternativa(texto: 'O roubo não admite pena de reclusão', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp8',
        enunciado: 'O que se entende por imputabilidade penal?',
        alternativas: [
          Alternativa(texto: 'A obrigação de reparar o dano causado à vítima', isCorreta: false),
          Alternativa(texto: 'A capacidade de entender o caráter ilícito do fato e de determinar-se de acordo com esse entendimento', isCorreta: true),
          Alternativa(texto: 'A presença de dolo na conduta', isCorreta: false),
          Alternativa(texto: 'A confissão do agente perante a autoridade', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp9',
        enunciado: 'Quais são as três esferas de responsabilidade que podem decorrer de um mesmo fato, segundo o ordenamento jurídico brasileiro?',
        alternativas: [
          Alternativa(texto: 'Penal, civil e administrativa', isCorreta: true),
          Alternativa(texto: 'Trabalhista, tributária e eleitoral', isCorreta: false),
          Alternativa(texto: 'Constitucional, processual e material', isCorreta: false),
          Alternativa(texto: 'Federal, estadual e municipal', isCorreta: false),
        ],
      ),
      Questao(
        id: 'dp10',
        enunciado: 'O que caracteriza o estado de necessidade como excludente de ilicitude?',
        alternativas: [
          Alternativa(texto: 'Sacrificar bem alheio para salvar de perigo atual bem próprio ou de terceiro, não evitável de outro modo', isCorreta: true),
          Alternativa(texto: 'Agir sob determinação de superior hierárquico', isCorreta: false),
          Alternativa(texto: 'Consentimento da vítima para a prática do fato', isCorreta: false),
          Alternativa(texto: 'Desconhecimento da lei penal', isCorreta: false),
        ],
      ),
    ],
  ),
  Materia(
    id: '4',
    descricao: 'Direito Processual Civil',
    questoes: <Questao>[
      Questao(
        id: 'pc1',
        enunciado: 'O que é a petição inicial, no processo civil?',
        alternativas: [
          Alternativa(texto: 'A peça que dá início ao processo, contendo o pedido e a causa de pedir', isCorreta: true),
          Alternativa(texto: 'A decisão final proferida pelo juiz', isCorreta: false),
          Alternativa(texto: 'O recurso cabível contra a sentença', isCorreta: false),
          Alternativa(texto: 'A defesa apresentada pelo réu', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc2',
        enunciado: 'Segundo o Código de Processo Civil de 2015, qual é o prazo geral para a apresentação da contestação?',
        alternativas: [
          Alternativa(texto: '5 dias úteis', isCorreta: false),
          Alternativa(texto: '10 dias úteis', isCorreta: false),
          Alternativa(texto: '15 dias úteis', isCorreta: true),
          Alternativa(texto: '30 dias úteis', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc3',
        enunciado: 'O que se entende por competência, no processo civil?',
        alternativas: [
          Alternativa(texto: 'A medida da jurisdição, ou seja, a distribuição do poder jurisdicional entre os órgãos judiciários', isCorreta: true),
          Alternativa(texto: 'O prazo para o juiz proferir sentença', isCorreta: false),
          Alternativa(texto: 'A qualidade da decisão transitada em julgado', isCorreta: false),
          Alternativa(texto: 'A capacidade postulatória das partes', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc4',
        enunciado: 'Qual recurso é cabível contra a sentença proferida em primeiro grau de jurisdição?',
        alternativas: [
          Alternativa(texto: 'Agravo de instrumento', isCorreta: false),
          Alternativa(texto: 'Apelação', isCorreta: true),
          Alternativa(texto: 'Recurso especial', isCorreta: false),
          Alternativa(texto: 'Embargos infringentes', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc5',
        enunciado: 'O que é a coisa julgada, no processo civil?',
        alternativas: [
          Alternativa(texto: 'A qualidade que torna imutável e indiscutível a decisão de mérito não mais sujeita a recurso', isCorreta: true),
          Alternativa(texto: 'A citação válida do réu', isCorreta: false),
          Alternativa(texto: 'O ato de distribuição do processo', isCorreta: false),
          Alternativa(texto: 'A produção antecipada de provas', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc6',
        enunciado: 'O que caracteriza a concessão da tutela de urgência?',
        alternativas: [
          Alternativa(texto: 'A existência de prova pré-constituída documental', isCorreta: false),
          Alternativa(texto: 'A demonstração de probabilidade do direito e perigo de dano ou risco ao resultado útil do processo', isCorreta: true),
          Alternativa(texto: 'O trânsito em julgado da decisão anterior', isCorreta: false),
          Alternativa(texto: 'A concordância expressa da parte contrária', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc7',
        enunciado: 'Qual princípio processual garante às partes o direito de serem ouvidas e de influenciar a decisão antes de sua prolação?',
        alternativas: [
          Alternativa(texto: 'Princípio da publicidade', isCorreta: false),
          Alternativa(texto: 'Princípio do contraditório', isCorreta: true),
          Alternativa(texto: 'Princípio da oralidade', isCorreta: false),
          Alternativa(texto: 'Princípio da instrumentalidade das formas', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc8',
        enunciado: 'O que é a revelia, no processo civil?',
        alternativas: [
          Alternativa(texto: 'A ausência de contestação pelo réu no prazo legal, gerando presunção de veracidade dos fatos alegados', isCorreta: true),
          Alternativa(texto: 'A desistência da ação pelo autor', isCorreta: false),
          Alternativa(texto: 'A extinção do processo sem resolução de mérito', isCorreta: false),
          Alternativa(texto: 'A suspensão do processo por convenção das partes', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc9',
        enunciado: 'Além do Ministério Público, quem mais pode ter legitimidade para propor ação civil pública, segundo a legislação processual?',
        alternativas: [
          Alternativa(texto: 'Apenas pessoas físicas maiores de idade', isCorreta: false),
          Alternativa(texto: 'Entes públicos e associações constituídas para a defesa de interesses difusos e coletivos', isCorreta: true),
          Alternativa(texto: 'Somente advogados particulares', isCorreta: false),
          Alternativa(texto: 'Apenas o réu do processo original', isCorreta: false),
        ],
      ),
      Questao(
        id: 'pc10',
        enunciado: 'Qual é a finalidade dos embargos de declaração?',
        alternativas: [
          Alternativa(texto: 'Reformar integralmente o mérito da decisão', isCorreta: false),
          Alternativa(texto: 'Sanar obscuridade, contradição, omissão ou erro material na decisão', isCorreta: true),
          Alternativa(texto: 'Suspender a execução da sentença por tempo indeterminado', isCorreta: false),
          Alternativa(texto: 'Substituir o recurso de apelação', isCorreta: false),
        ],
      ),
    ],
  ),
];