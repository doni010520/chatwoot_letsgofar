# frozen_string_literal: true

# Template de Contrato de Aulas em Grupo - Let's Go Far
# Baseado no PDF "contrato_-_executive_class_.pdf"
# Execute no rails console: load 'db/seeds_aulas_grupo.rb'

template_aulas_grupo = <<~HTML
<div style="font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6;">
  
  <!-- Logo -->
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://letsgofaridiomas.com/wp-content/uploads/2024/01/logo-lets-go-far.png" alt="Let's Go Far" style="max-width: 150px;" onerror="this.style.display='none'">
  </div>

  <h1 style="text-align: center; color: #333333; font-size: 24px; margin-bottom: 30px;">
    CONTRATO DE PRESTAÇÃO DE SERVIÇOS
  </h1>

  <p style="text-align: justify;">
    Para fins deste contrato, os termos abaixo terão os seguintes significados:
  </p>

  <!-- CONTRATANTE -->
  <h3 style="color: #333333; margin-top: 25px;">CONTRATANTE ("ALUNO" | "MENTORADO")</h3>
  <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
    <tr><td style="padding: 8px; border: 1px solid #ddd; width: 200px;"><strong>Nome do aluno:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_name}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>CPF/MF do aluno:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_cpf}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>RG do aluno:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_rg}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Endereço:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_street}}, {{contractor_number}}<br>{{contractor_complement}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Bairro:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_neighborhood}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Município:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_city}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>CEP:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_cep}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Estado:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_state}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>E-mail:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_email}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Telefone:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_phone}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Data de nascimento:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{contractor_birthdate}}</td></tr>
  </table>

  <!-- Representante Legal (menor de 18 anos) -->
  <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
    <tr><td style="padding: 8px; border: 1px solid #ddd; width: 280px;"><strong>Representante legal (menor 18 anos):</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{legal_representative_name}}</td></tr>
    <tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>CPF/MF Representante legal:</strong></td><td style="padding: 8px; border: 1px solid #ddd;">{{legal_representative_cpf}}</td></tr>
  </table>

  <!-- CONTRATADA -->
  <h3 style="color: #333333; margin-top: 25px;">CONTRATADA ("ESCOLA" | MENTORA)</h3>
  <p style="text-align: justify;">
    <strong>LETS GO FAR ENSINO DE IDIOMAS LTDA</strong> (LET'S GO FAR), inscrita no CNPJ nº 53.654.906/0001-96, 
    com sede na Rua Ipacaetá, 159, sala 04, Guarulhos/SP, CEP 07171-150 no Estado São Paulo, 
    telefone (11) 99777-3116, e-mail contato@letsgofaridiomas.com.
  </p>

  <h3 style="color: #333333; margin-top: 25px;">SERVIÇO</h3>
  <p><u>Aulas de inglês a distância ao vivo em grupo ("pacote de aulas")</u></p>

  <p style="text-align: justify; margin-top: 20px;">
    O presente contrato representa a totalidade do acordo entre as partes, substituindo quaisquer 
    entendimentos, negociações ou acordos anteriores que possam conflitar com as disposições aqui estabelecidas.
  </p>

  <p style="text-align: justify;">
    As Partes têm, entre si, celebrado o presente <strong>CONTRATO DE PRESTAÇÃO DE SERVIÇOS</strong>, de 
    acordo com as seguintes cláusulas e condições:
  </p>

  <!-- CLÁUSULA 1 - OBJETO -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>1. OBJETO DO CONTRATO</u></h2>
  
  <p style="text-align: justify;">
    <strong>1.1.</strong> O objeto deste contrato consiste na prestação de serviços de aulas de inglês a distância em grupo, conforme - ANEXO I deste instrumento.
  </p>
  
  <p style="text-align: justify;">
    <strong>Parágrafo primeiro:</strong> O serviço contratado será realizado na plataforma Google Meet, que deverá ser acessado pelo link enviado pela secretaria no prazo de 7 (sete) dias da data da contratação.
  </p>
  
  <p style="text-align: justify;">
    <strong>Parágrafo segundo:</strong> O CONTRATANTE terá acesso ao calendário de aulas no ato da contratação que contemplará dia das aulas, feriados e recesso.
  </p>
  
  <p style="text-align: justify;">
    <strong>Parágrafo terceiro:</strong> A CONTRATADA poderá alterar o calendário de aulas, mediante aviso prévio, cuja comunicação será realizada por WhatsApp cadastrado neste contrato.
  </p>
  
  <p style="text-align: justify;">
    <strong>Parágrafo quarto:</strong> A CONTRATADA poderá, a qualquer tempo e a seu exclusivo critério, sem qualquer ônus, remanejar ou fundir as turmas já formadas e/ou em andamento, desde que pertencentes ao nível (CEFR – classificação de Cambridge).
  </p>

  <!-- CLÁUSULA 2 - OBRIGAÇÕES DA CONTRATADA -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>2. OBRIGAÇÕES DA CONTRATADA</u></h2>
  
  <p style="text-align: justify;">
    <strong>2.1</strong> A CONTRADA compromete-se a buscar, de forma contínua, melhorias nos processos e serviços prestados, propondo soluções e inovações que possam beneficiar o CONTRATANTE.
  </p>
  
  <p style="text-align: justify;">
    <strong>2.2</strong> A CONTRATADA deve proporcionar um ensino que atenda aos padrões educacionais vigentes, assegurando que os professores sejam qualificados e que o conteúdo programático seja adequado ao nível e às expectativas dos alunos.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> o CONTRATANTE não possuirá professores fixos, podendo ser alterados pela CONTRATADA a qualquer tempo e a seu exclusivo critério.
  </p>
  
  <p style="text-align: justify;">
    <strong>2.3</strong> É responsabilidade da CONTRATADA disponibilizar e/ou indicar os materiais necessários para o acompanhamento das aulas, como livros, apostilas e recursos complementares (plataforma LET'S GO FAR PLUS).
  </p>
  
  <p style="text-align: justify;">
    <strong>2.4</strong> A CONTRATADA deve respeitar a carga horária estabelecida no contrato garantindo que as aulas sejam ministradas conforme o cronograma acordado.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> em caso de falta/ausência no dia da aula o CONTRATANTE poderá solicitar a gravação da aula.
  </p>
  
  <p style="text-align: justify;">
    <strong>2.5</strong> A CONTRATADA deve fornecer informações claras sobre o curso disponibilizadas no ANEXO I deste instrumento, incluindo objetivos, conteúdo programático, quantidade de aulas, duração aproximada, assegurando que o aluno esteja plenamente ciente dos serviços contratados.
  </p>
  
  <p style="text-align: justify;">
    <strong>2.6</strong> Ao término do pacote de aulas, a CONTRATADA é responsável por emitir certificados ou declarações que comprovem a conclusão e o aproveitamento do aluno, conforme previsto no contrato.
  </p>
  
  <p style="text-align: justify;">
    <strong>2.7</strong> A CONTRADA compromete-se a oferecer os conteúdos, aulas e orientações pedagógicas necessárias para o aprendizado da língua inglesa. Contudo, o progresso e desempenho do CONTRATANTE dependem de seu engajamento e dedicação, não sendo a CONTRATADA responsável por resultados específicos, considerando que a eficácia do curso está diretamente vinculada ao esforço individual do CONTRATANTE, sua assiduidade e cumprimento das atividades recomendadas.
  </p>

  <!-- CLÁUSULA 3 - OBRIGAÇÕES DO CONTRATANTE -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>3. OBRIGAÇÕES DO CONTRANTE</u></h2>
  
  <p style="text-align: justify;">
    <strong>3.1</strong> O CONTRATANTE é responsável por garantir o acesso à internet e a um dispositivo compatível com a plataforma Google Meet, onde serão realizadas as aulas. A CONTRATADA enviará o link de acesso por WhatsApp até 7 (sete) dias após a efetivação da contratação. O CONTRATANTE deve verificar o recebimento desse link e assegurar-se de estar preparado para o uso da plataforma nos horários agendados.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.2</strong> Como parte fundamental da comunicação entre as partes, o CONTRATANTE deve manter sempre atualizados os dados fornecidos no momento da contratação, especialmente o número de WhatsApp e o e-mail cadastrados. Isso é necessário para o recebimento de avisos importantes, como alterações de datas e horários das aulas, que serão comunicadas exclusivamente por esses canais. Caso ocorra a perda de acesso à comunicação por desatualização dos dados, a responsabilidade por quaisquer informações não recebidas será inteiramente do CONTRATANTE, sem ônus para a CONTRATADA.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.3</strong> Considerando que as aulas são realizadas ao vivo e em grupo, a pontualidade é essencial para que o CONTRATANTE aproveite ao máximo o conteúdo. É sua responsabilidade acessar o link no horário estabelecido e acompanhar o cronograma das aulas para evitar interrupções ou atrasos, que podem prejudicar o aprendizado e a experiência dos demais alunos.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.4</strong> O CONTRATANTE declara-se ciente de que o não comparecimento às aulas não será interpretado pela CONTRATADA como desistência e/ou como intenção de resilição do contrato, de modo que este fato não isentará de pagar valores que se encontrem em atraso e/ou que venham a vencer.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> A CONTRATADA não garante ao CONTRATANTE, após 4 aulas consecutivas ausentes e sem comunicação, o horário das aulas.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.5</strong> Como o curso será oferecido a distância, o CONTRATANTE deve garantir uma conexão de internet estável e adequada, bem como dispositivos (computador, tablet ou celular) que possibilitem o acompanhamento das aulas com qualidade. Problemas técnicos ou de conexão que impeçam o CONTRATANTE de acessar as aulas são de sua responsabilidade e não geram qualquer obrigação de reposição ou ressarcimento pela CONTRATADA.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.6</strong> O CONTRATANTE deve comportar-se de forma respeitosa e colaborativa durante as aulas, contribuindo para um ambiente de aprendizado saudável e construtivo para todos os participantes. Qualquer comportamento disruptivo ou desrespeitoso pode resultar em sanções estabelecidas pela CONTRATADA, que ocorrerão na seguinte ordem: advertência verbal, remoção do ambiente virtual de aula, e rescisão contratual por justo motivo.
  </p>
  
  <p style="text-align: justify;">
    <strong>3.7</strong> Para assegurar o cumprimento dos objetivos de aprendizado contratados, o CONTRATANTE deve aderir rigorosamente a uma série de requisitos que visam maximizar a eficiência do curso de inglês. São eles:
  </p>
  
  <ul style="text-align: justify; margin-left: 20px;">
    <li style="margin-bottom: 10px;"><strong>Acesso Diário à Plataforma Let's GO FAR PLUS:</strong> Para obter um aprendizado contínuo e eficaz, o aluno deverá acessar a plataforma Let's GO FAR PLUS diariamente, seguindo o cronograma disponibilizado. Recomenda-se um tempo mínimo de 30 minutos por dia para o estudo dos conteúdos e atividades, sendo ideal dedicar cerca de 1 hora para consolidar os conhecimentos adquiridos. É essencial que o aluno progrida de acordo com os módulos e etapas sugeridos na plataforma, respeitando a sequência do cronograma.</li>
    
    <li style="margin-bottom: 10px;"><strong>Participação nas Aulas Extras ao Vivo:</strong> Além das atividades na plataforma, o CONTRATANTE deve comparecer às aulas extras ao vivo, que são uma oportunidade de aprofundamento e interação em grupo com colegas e instrutores. Essas aulas ocorrem mensalmente e são previamente comunicadas pelos canais oficiais da escola, incluindo WhatsApp e redes sociais. A participação ativa nessas aulas é altamente recomendada para o desenvolvimento das habilidades linguísticas e a prática de conversação.</li>
    
    <li style="margin-bottom: 10px;"><strong>Assiduidade de 80% nas Aulas:</strong> A presença constante é essencial para o progresso contínuo no curso. Para garantir um nível satisfatório de aprendizado, o aluno deve ter uma assiduidade mínima de 80% nas aulas ao vivo, tanto as regulares quanto as extras. A presença em sala é importante para acompanhar o conteúdo e as atividades realizadas em grupo.</li>
    
    <li style="margin-bottom: 10px;"><strong>Pontualidade:</strong> A pontualidade também é um aspecto fundamental no ambiente virtual de aprendizado. Chegar pontualmente às aulas ao vivo demonstra comprometimento e evita interrupções no fluxo da aula, beneficiando o aluno e os colegas de curso.</li>
  </ul>

  <!-- CLÁUSULA 4 - VALORES E TAXAS -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>4. VALORES E TAXAS</u></h2>
  
  <p style="text-align: justify;">
    <strong>4.1</strong> Os valores dos serviços prestados deverão ser pagos pelo CONTRATANTE conforme o valor e condições de pagamentos especificados no ANEXO I deste instrumento. O pagamento deverá ocorrer rigorosamente nas condições e prazos pactuados, sendo essencial para a continuidade dos serviços.
  </p>
  
  <p style="text-align: justify;">
    <strong>4.2</strong> Em caso de atraso no pagamento, o CONTRATANTE estará sujeito à aplicação de multa de 2% (dois por cento) sobre o valor em atraso, além de juros de mora de 1% (um por cento) ao mês, calculados proporcionalmente aos dias de atraso, a partir do primeiro dia após o vencimento até a data da quitação integral.
  </p>
  
  <p style="text-align: justify;">
    <strong>4.3</strong> Em caso de inadimplência superior a 30 (trinta) dias, o nome do CONTRATANTE poderá ser inscrito em órgãos de proteção ao crédito, como SPC e Serasa, sem necessidade de aviso prévio, até que a dívida seja totalmente regularizada.
  </p>
  
  <p style="text-align: justify;">
    <strong>4.4</strong> Na hipótese de cobrança judicial, o CONTRATANTE será responsável pelo pagamento de honorários advocatícios, fixados em 10% (dez por cento) sobre o valor total da dívida, acrescidos de eventuais custas e despesas processuais associadas à cobrança.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> A aplicação das penalidades e encargos aqui previstos ocorrerá automaticamente em caso de inadimplência, sem a necessidade de notificação prévia. O pagamento dos encargos e da eventual inscrição nos órgãos de proteção ao crédito não exime o CONTRATANTE da obrigação de quitar o valor principal devido.
  </p>

  <!-- CLÁUSULA 5 - PRAZO DE VIGÊNCIA -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>5. PRAZO DE VIGÊNCIA</u></h2>
  
  <p style="text-align: justify;">
    <strong>5.1.</strong> O presente contrato terá vigência conforme cronograma de aulas e pacote de aulas contratados, nos termos do ANEXO I deste instrumento.
  </p>

  <!-- CLÁUSULA 6 - RESCISÃO CONTRATUAL -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>6. RESCISÃO CONTRATUAL</u></h2>
  
  <p style="text-align: justify;">
    <strong>6.1</strong> Em conformidade com o artigo 49 do Código de Defesa do Consumidor, o CONTRATANTE tem o direito de desistir do contrato no prazo de 7 (sete) dias, contados a partir dos dados de assinatura do contrato, caso a contratação tenha ocorrido fora do estabelecimento comercial. Neste caso, a rescisão será realizada sem qualquer ônus ao CONTRATANTE, e os valores eventualmente pagos serão devolvidos integralmente pela CONTRATADA.
  </p>
  
  <p style="text-align: justify;">
    <strong>6.2</strong> Decorrido o prazo de 7 (sete) dias para o exercício do direito de arrependimento, o CONTRATANTE poderá rescindir o contrato mediante o pagamento de multa rescisória equivalente a 20% (vinte por cento) do valor correspondente ao saldo remanescente do contrato. Essa multa visa compensar a CONTRATADA pelas despesas operacionais e administrativas decorrentes do encerramento antecipado dos serviços e o acesso a Plataforma digital LET'S GO FAR PLUS disponibilizada integralmente no momento da assinatura não sendo de trato sucessivo.
  </p>
  
  <p style="text-align: justify;">
    <strong>6.3</strong> A rescisão do contrato deverá ser formalizada pelo CONTRATANTE por meio de comunicação escrita enviada à CONTRATADA, pelo WhatsApp, que informará o cálculo do valor da multa rescisória, se aplicável, e os procedimentos para a encerramento das obrigações contratuais.
  </p>
  
  <p style="text-align: justify;">
    <strong>6.4</strong> Com a rescisão, todos os serviços serão imediatamente suspensos e os acessos a plataforma e conteúdos complementares serão desativados.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> A rescisão do contrato não exime o CONTRATANTE do pagamento de débitos pendentes ou de encargos contratuais eventualmente aplicáveis até a data da rescisão, sendo devida a quitação integral do saldo em conformidade com as condições aqui estipuladas.
  </p>

  <!-- CLÁUSULA 7 - DIREITO DE IMAGEM -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>7. DIREITO DE IMAGEM E AUTORIZAÇÃO PARA GRAVAÇÃO E USO DE AULAS</u></h2>
  
  <p style="text-align: justify;">
    <strong>7.1.</strong> O CONTRATANTE declara estar ciente e autoriza a gravação de todas as aulas realizadas durante o curso. Os direitos autorais poderão ser utilizados pela CONTRATADA para fins internos, passando pela revisão de conteúdo e o aprimoramento do aprendizado, bem como para fins promocionais, conforme descrito nesta cláusula.
  </p>
  
  <p style="text-align: justify;">
    <strong>7.2</strong> O CONTRATANTE autoriza a CONTRATADA a utilizar trechos das gravações das aulas, incluindo sua imagem, voz e participação, para a produção de materiais de divulgação destinados à promoção do trabalho da escola de idiomas, especialmente em redes sociais, no site institucional e em outras mídias relacionadas à CONTRATADA.
  </p>
  
  <p style="text-align: justify;">
    <strong>7.3</strong> Os trechos das aulas gravados serão selecionados e editados exclusivamente para promover os serviços da CONTRATADA, de forma a ilustrar o ambiente educacional, a metodologia de ensino e a interação entre alunos e instrutores, sempre respeitando a imagem e integridade do CONTRATANTE.
  </p>
  
  <p style="text-align: justify;">
    <strong>7.4</strong> O CONTRATANTE declara estar ciente e concorda, de forma livre e espontânea, que sua imagem, voz e participação nas aulas poderão ser captadas, editadas e divulgadas pela CONTRATADA, exclusivamente para os fins de promoção do trabalho da escola, sem que isso implique em quaisquer pagamentos ou compensações.
  </p>
  
  <p style="text-align: justify;">
    <strong>7.5</strong> O CONTRATANTE poderá revogar essa autorização a qualquer momento, mediante comunicação formal por escrito à CONTRATADA. No entanto, a CONTRATADA não ficará obrigada a remover materiais já publicados antes dos dados de pedido de revogação, mas compromete-se a cessar o uso de novas gravações que envolvam o CONTRATANTE para os fins promocionais.
  </p>
  
  <p style="text-align: justify;">
    <strong>7.6</strong> Ao conceder esta autorização, o CONTRATANTE renuncia a qualquer tipo de remuneração, indenização ou indenização pelo uso de sua imagem, voz ou participação nas gravações das aulas para os fins promocionais da CONTRATADA, conforme as específicas disposições nesta cláusula.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>Parágrafo único:</strong> A CONTRATADA compromete-se a utilizar a imagem e a voz do CONTRATANTE de forma respeitosa e responsável, preservando a ética e a integridade do CONTRATANTE em todas as divulgações, alinhando-se aos princípios de transparência e respeito mútuo que regem a relação entre as partes.
  </p>

  <!-- CLÁUSULA 8 - PROTEÇÃO DE DADOS -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>8. PROTEÇÃO DE DADOS</u></h2>
  
  <p style="text-align: justify;">
    <strong>8.1.</strong> A CONTRATADA compromete-se a tratar os dados pessoais do CONTRATANTE exclusivamente para as finalidades relacionadas à execução deste contrato, observadas integralmente as disposições da Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 – LGPD). O tratamento inclui a coleta, armazenamento, uso, compartilhamento, entre outros processos necessários para o cumprimento das obrigações contratuais.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.2</strong> Os dados pessoais do CONTRATANTE serão usados apenas para as finalidades acordadas e permitir o bom desempenho dos serviços prestados. A CONTRATADA não utilizará esses dados para outras finalidades específicas, nem os compartilhará com terceiros, salvo quando necessário para a execução dos serviços ou quando exigido por lei.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.3</strong> O CONTRATANTE declara estar ciente e concordar com o tratamento de seus dados pessoais em conformidade com as disposições desta cláusula. O CONTRATANTE poderá, a qualquer momento, exercer seus direitos previstos na LGPD, incluindo o acesso, correção, atualização e exclusão de dados pessoais, nos termos da legislação aplicável.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.4</strong> A CONTRATADA adota medidas técnicas e administrativas específicas para proteger os dados pessoais do CONTRATANTE contra acessos não autorizados, vazamentos, alterações, perdas ou quaisquer outros incidentes de segurança. Essas medidas são inovadoras em conformidade com os padrões de segurança da informação vigentes e são atualizadas regularmente para garantir a integridade dos dados.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.5</strong> A CONTRATADA poderá compartilhar os dados pessoais do CONTRATANTE com parceiros ou falar de serviços, exclusivamente para os fins de execução das atividades previstas neste contrato, garantindo que esses terceiros também se comprometam a observar as normas de proteção de dados em conformidade com a LGPD.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.6</strong> Os dados pessoais do CONTRATANTE serão mantidos pela CONTRATADA apenas pelo tempo necessário ao cumprimento das finalidades contratuais ou conforme exigido pela legislação. Após o término desse período, os dados serão excluídos de forma segura, salvo quando houver obrigações legais ou regulamentares de manutenção.
  </p>
  
  <p style="text-align: justify;">
    <strong>8.7</strong> Na eventual ocorrência de um incidente de segurança que não resulte em vazamento de dados pessoais do CONTRATANTE, a CONTRATADA adotará as seguintes providências:
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>a) Notificação:</strong> A CONTRATADA informará o CONTRATANTE sobre o incidente em tempo hábil, fornecendo informações sobre a natureza do vazamento, os dados pessoais afetados e as possíveis consequências para o titular.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>b) Adoção de Medidas Corretivas:</strong> A CONTRATADA tomará imediatamente todas as medidas possíveis para conter e mitigar os efeitos do incidente, incluindo a implementação de procedimentos adicionais de segurança para evitar a recorrência de tais eventos.
  </p>
  
  <p style="text-align: justify; margin-left: 20px;">
    <strong>c) Comunicação às Autoridades Competentes:</strong> Quando necessário, a CONTRATADA comunicará o incidente às autoridades competentes, em conformidade com as exigências da LGPD e demais normas aplicáveis, informando as medidas adotadas para mitigar o impacto do vazamento e proteger os direitos do titular dos dados.
  </p>

  <!-- CLÁUSULA 9 - CASO FORTUITO OU FORÇA MAIOR -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>9. CASO FORTUITO OU FORÇA MAIOR</u></h2>
  
  <p style="text-align: justify;">
    <strong>9.1</strong> Nenhuma das partes será responsabilizada pelo não cumprimento ou pelo cumprimento inadequado das obrigações contratuais quando tal inadimplência resultar de casos fortuitos ou de força maior, nos termos do artigo 393 do Código Civil Brasileiro. -se por caso fortuito ou força maior todo e qualquer evento planejado e imprevisível, alheio à vontade das partes, que impeça ou dificulte o cumprimento das obrigações previstas no contrato neste, como, mas não se limitando a, desastres naturais, pandemias, atos de governo, guerras, greves, falhas de infraestrutura elétrica e de internet, e demais situações fora do controle das partes.
  </p>
  
  <p style="text-align: justify;">
    <strong>9.2</strong> No caso de ocorrência de evento caracterizado como caso fortuito ou força maior, as obrigações afetadas por tal evento serão suspensas enquanto perdurarem os efeitos do impedimento, não sendo devidas prejuízos ou indenizações pela parte prejudicada. As partes deverão envidar seus melhores esforços para mitigar os efeitos do evento e buscar alternativas viáveis para a continuidade do contrato, se possível.
  </p>
  
  <p style="text-align: justify;">
    <strong>9.3</strong> A parte impactada por evento de caso fortuito ou força maior deverá notificar a outra parte, por escrito, no menor prazo possível, informando sobre a ocorrência, a natureza do evento e a extensão de seu impacto nas obrigações contratuais. Deverá também manter a outra parte informada sobre o andamento do evento e as medidas que estão sendo tomadas para minimizar os seus efeitos.
  </p>

  <!-- CLÁUSULA 10 - COMUNICAÇÃO -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>10. COMUNICAÇÃO</u></h2>
  
  <p style="text-align: justify;">
    <strong>10.1.</strong> Todas as comunicações entre as partes relacionadas à execução deste contrato deverão ser realizadas por escrito, preferencialmente pelo canal de WhatsApp previamente informado e cadastrado. Esse canal será utilizado para tratar de qualquer assunto relacionado a serviços, dúvidas, alterações e demais notificações pertinentes ao contrato.
  </p>
  
  <p style="text-align: justify;">
    <strong>10.2</strong> Em casos de solicitação de cancelamento do contrato, o CONTRATANTE deverá formalizar seu pedido exclusivamente por escrito, através de mensagem de texto enviada pelo WhatsApp, sendo expressamente vedada a utilização de mensagens de áudio para esse fim. A CONTRATADA não considerará válidos pedidos de cancelamento enviados em formato de áudio.
  </p>
  
  <p style="text-align: justify;">
    <strong>10.3</strong> A CONTRATADA compromete-se a confirmar a coleta de todas as comunicações de cancelamento enviadas pelo CONTRATANTE, no prazo de até 2 (dois) dias úteis, por meio de uma mensagem de resposta escrita no mesmo canal do WhatsApp. Em caso de ausência de confirmação dentro desse prazo, o CONTRATANTE deverá reiterar a comunicação até que seja recebida a confirmação.
  </p>

  <!-- CLÁUSULA 11 - RESOLUÇÃO DE CONFLITO E FORO -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>11. RESOLUÇÃO DE CONFLITO E FORO</u></h2>
  
  <p style="text-align: justify;">
    <strong>11.1.</strong> As partes comprometem-se a resolver de forma amigável qualquer divergência relativa a este contrato. Na impossibilidade de acordo, elegem o foro da comarca de Guarulhos/SP como competente.
  </p>

  <!-- CLÁUSULA 12 - ASSINATURA DIGITAL -->
  <h2 style="color: #333333; margin-top: 30px; border-bottom: 2px solid #333333; padding-bottom: 5px;"><u>12. ASSINATURA DIGITAL</u></h2>
  
  <p style="text-align: justify;">
    <strong>12.1</strong> As partes, por estarem justas e acordadas, assinam este contrato de prestação de serviços de forma digital, conforme o artigo 784, §4º, do Código de Processo Civil/2015 e Lei nº 14.620, de 2023, que permite a assinatura eletrônica, dispensando a presença de testemunhas quando sua integridade é verificada por provedor de assinatura.
  </p>
  
  <p style="text-align: justify;">
    <strong>12.2</strong> A assinatura digital terá plena validade jurídica, conferindo a este contrato força executiva e eficácia equivalente à assinatura manuscrita.
  </p>
  
  <p style="text-align: justify;">
    <strong>12.3.</strong> Ao negociarem digitalmente, as partes declaram ter lido e compreendido o teor deste contrato, estando de acordo com todos os seus termos.
  </p>

  <p style="text-align: center; margin-top: 40px; font-weight: bold;">
    Guarulhos/SP, {{contract_date}}
  </p>

  <!-- Assinaturas -->
  <div style="margin-top: 50px; display: flex; justify-content: space-between;">
    <div style="text-align: center; width: 45%;">
      <p style="border-top: 1px solid #333; padding-top: 10px;">
        <strong>LETS GO FAR ENSINO DE IDIOMAS LTDA</strong><br>
        CONTRATADA
      </p>
    </div>
    <div style="text-align: center; width: 45%;">
      <p style="border-top: 1px solid #333; padding-top: 10px;">
        <strong>{{contractor_name}}</strong><br>
        CONTRATANTE
      </p>
    </div>
  </div>

  <!-- ANEXO I -->
  <div style="page-break-before: always; margin-top: 60px; border-top: 3px solid #333333; padding-top: 30px;">
    <h2 style="text-align: center; color: #333333;">ANEXO I</h2>
    
    <!-- Condições de Pagamento -->
    <h3 style="color: #333333; margin-top: 20px;">Condições de pagamento:</h3>
    
    <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5; width: 280px;"><strong>Taxa Única de Matrícula:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{enrollment_fee}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Plano contratado:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{plan_name}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Quantidade de aulas:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{lessons_count}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Duração aproximada:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{plan_duration}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Início do plano:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{plan_start_date}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Término do plano:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{plan_end_date}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Valor do plano contratado:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{plan_value}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Parcelado:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{installments_count}} meses</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>1ª parcela:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{first_installment_date}} (ato da matrícula)</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Demais parcelas com vencimento todo dia:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">{{installment_due_day}}</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #ddd; background-color: #f5f5f5;"><strong>Forma de pagamento:</strong></td>
        <td style="padding: 10px; border: 1px solid #ddd;">Boleto ou PIX</td>
      </tr>
    </table>

    <!-- Descrição do Plano -->
    <h3 style="color: #333333; margin-top: 30px;">Descrição do Plano - Aulas de Inglês em Grupo</h3>
    
    <p style="text-align: justify;">
      Neste plano, as aulas em grupo são formadas por alunos do mesmo nível de proficiência, garantindo interações mais eficazes e uma comunicação relevante durante as atividades.
    </p>
    
    <p style="text-align: justify;">
      As aulas são estruturadas para desenvolver as quatro habilidades do inglês — fala, escuta, leitura e escrita — com foco em aplicações práticas do dia a dia e do contexto profissional de cada aluno.
    </p>
    
    <h4 style="color: #333333; margin-top: 20px;">O QUE VOCÊ VAI DESENVOLVER NAS AULAS</h4>
    
    <p style="text-align: justify;">
      <strong>Revisão de Gramática</strong><br>
      Trabalhamos os principais pontos gramaticais que causam dúvidas, ajudando você a construir uma base sólida para se comunicar com segurança.
    </p>
    
    <p style="text-align: justify;">
      <strong>Técnicas de Pronúncia</strong><br>
      Desenvolvemos sua pronúncia para que seu inglês soe mais natural e compreensível.
    </p>
    
    <p style="text-align: justify;">
      <strong>Expansão de Vocabulário</strong><br>
      Você aprende e pratica vocabulário essencial para se expressar com clareza em diferentes situações.
    </p>
    
    <p style="text-align: justify;">
      <strong>Escuta Ativa</strong><br>
      Treinamos sua compreensão auditiva com diferentes sotaques e contextos reais.
    </p>
    
    <p style="text-align: justify;">
      <strong>Prática de Escrita</strong><br>
      Exercícios aplicados ao cotidiano, como emails, mensagens, relatórios ou textos práticos.
    </p>
    
    <p style="text-align: justify;">
      <strong>Desenvolvimento da Conversação</strong><br>
      Atividades práticas para melhorar sua fluência, organizar ideias e evitar bloqueios ao falar inglês.
    </p>
    
    <h4 style="color: #333333; margin-top: 20px;">PARA QUEM ESTE PLANO É INDICADO</h4>
    
    <p style="text-align: justify;">
      Este plano é ideal para profissionais e estudantes que desejam desenvolver segurança para se comunicar em inglês, seja no ambiente profissional, em viagens ou em situações do cotidiano.
    </p>
  </div>
</div>
HTML

# Atualizar ou criar o template
template = ContractTemplate.find_or_initialize_by(name: 'Aulas em Grupo - Let\'s Go Far')
template.user = User.first
template.description = 'Contrato de Aulas de Inglês em Grupo a Distância - Let\'s Go Far'
template.content_html = template_aulas_grupo
template.variable_fields = [
  # Dados do Contratante
  { key: 'contractor_name', label: 'Nome do Aluno', type: 'text', required: true },
  { key: 'contractor_cpf', label: 'CPF', type: 'cpf', required: true },
  { key: 'contractor_rg', label: 'RG', type: 'text', required: false },
  { key: 'contractor_street', label: 'Rua', type: 'text', required: true },
  { key: 'contractor_number', label: 'Número', type: 'text', required: true },
  { key: 'contractor_complement', label: 'Complemento', type: 'text', required: false },
  { key: 'contractor_neighborhood', label: 'Bairro', type: 'text', required: true },
  { key: 'contractor_city', label: 'Município', type: 'text', required: true },
  { key: 'contractor_cep', label: 'CEP', type: 'cep', required: true },
  { key: 'contractor_state', label: 'Estado', type: 'state', required: true },
  { key: 'contractor_email', label: 'E-mail', type: 'email', required: true },
  { key: 'contractor_phone', label: 'Telefone', type: 'phone', required: true },
  { key: 'contractor_birthdate', label: 'Data de Nascimento', type: 'date', required: true },
  # Representante Legal (menores de 18 anos)
  { key: 'legal_representative_name', label: 'Nome do Representante Legal (menor 18 anos)', type: 'text', required: false },
  { key: 'legal_representative_cpf', label: 'CPF do Representante Legal', type: 'cpf', required: false },
  # Dados do Plano
  { key: 'enrollment_fee', label: 'Taxa de Matrícula', type: 'currency', required: false },
  { key: 'plan_name', label: 'Nome do Plano', type: 'text', required: true },
  { key: 'lessons_count', label: 'Quantidade de Aulas', type: 'text', required: true },
  { key: 'plan_duration', label: 'Duração Aproximada', type: 'text', required: true },
  { key: 'plan_start_date', label: 'Início do Plano', type: 'date', required: true },
  { key: 'plan_end_date', label: 'Término do Plano (calculado automaticamente)', type: 'date', required: false },
  { key: 'plan_value', label: 'Valor Total do Plano', type: 'currency', required: true },
  { key: 'installments_count', label: 'Número de Parcelas', type: 'number', required: true },
  { key: 'first_installment_date', label: 'Data 1ª Parcela (Matrícula)', type: 'date', required: true },
  { key: 'installment_due_day', label: 'Dia de Vencimento das Parcelas', type: 'date', required: true },
  { key: 'contract_date', label: 'Data do Contrato (por extenso)', type: 'text', required: true }
]
template.active = true
template.save!

puts '✅ Template "Aulas em Grupo - Let\'s Go Far" criado/atualizado com sucesso!'
puts "   - #{template.variable_fields.count} campos configurados"
puts "   - Contrato idêntico ao PDF original"
puts "   - Anexo I substituído pela descrição de Aulas em Grupo"
puts "   - Campos de início e término do plano incluídos"
