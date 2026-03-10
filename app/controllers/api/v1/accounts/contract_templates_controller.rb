# frozen_string_literal: true

class Api::V1::Accounts::ContractTemplatesController < Api::V1::Accounts::BaseController
  before_action :set_template, only: [:show, :update, :destroy, :preview]

  def index
    @templates = Current.account.contract_templates
                        .includes(:created_by)
                        .order(created_at: :desc)

    @templates = @templates.active if params[:active_only].present?

    render json: {
      data: @templates.map { |t| template_json(t) }
    }
  end

  def show
    render json: { data: template_json(@template, full: true) }
  end

  def create
    @template = Current.account.contract_templates.new(template_params)
    @template.created_by = Current.user

    if @template.save
      render json: { data: template_json(@template, full: true) }, status: :created
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(template_params)
      render json: { data: template_json(@template, full: true) }
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy!
    head :no_content
  end

  def preview
    variables = params[:variables] || {}
    rendered_html = @template.apply_variables(variables)

    render json: {
      html: rendered_html,
      missing_fields: @template.validate_variables(variables)
    }
  end

  # Retorna o template padrão da Let's Go Far
  def default
    render json: {
      data: {
        name: 'Contrato Padrão - Let\'s Go Far',
        variable_fields: ContractTemplate::DEFAULT_VARIABLE_FIELDS,
        content_html: default_contract_html
      }
    }
  end

  private

  def set_template
    @template = Current.account.contract_templates.find(params[:id])
  end

  def template_params
    params.require(:contract_template).permit(
      :name,
      :description,
      :content_html,
      :active,
      variable_fields: [:key, :label, :type, :required]
    )
  end

  def template_json(template, full: false)
    data = {
      id: template.id,
      name: template.name,
      description: template.description,
      active: template.active,
      created_at: template.created_at,
      created_by: template.created_by ? {
        id: template.created_by.id,
        name: template.created_by.display_name || template.created_by.name
      } : nil
    }

    if full
      data.merge!(
        content_html: template.content_html,
        variable_fields: template.variable_fields.presence || ContractTemplate::DEFAULT_VARIABLE_FIELDS,
        placeholders: template.extract_placeholders
      )
    end

    data
  end

  def default_contract_html
    <<~HTML
      <div style="font-family: Arial, sans-serif; font-size: 12pt; line-height: 1.6; color: #333;">
        <h1 style="text-align: center; color: #8B0000; font-size: 18pt; margin-bottom: 30px;">
          CONTRATO DE PRESTAÇÃO DE SERVIÇOS DE ASSESSORIA CONSULTIVA DE INGLÊS
        </h1>

        <p style="text-align: justify;">
          Pelo presente instrumento particular, de um lado <strong>LETS GO FAR ENSINO DE IDIOMAS LTDA</strong>, 
          pessoa jurídica de direito privado, inscrita no CNPJ sob o nº 53.654.906/0001-96, com sede na 
          Rua Ipacaetá, 159, sala 04, Guarulhos/SP, CEP 07171-150, telefone (11) 99777-3116, 
          e-mail contato@letsgofaridiomas.com, doravante denominada <strong>CONTRATADA</strong>, e de outro lado:
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CONTRATANTE</h2>
        
        <table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold; width: 200px;">Nome Completo:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_name}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">CPF:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_cpf}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">RG:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_rg}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Endereço:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_address}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Bairro:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_neighborhood}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Cidade/Estado:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_city}} - {{contractor_state}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">CEP:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_cep}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">E-mail:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_email}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Telefone:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_phone}}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Data de Nascimento:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{contractor_birth_date}}</td>
          </tr>
        </table>

        <p style="text-align: justify;">
          As partes acima identificadas têm, entre si, justo e acertado o presente Contrato de Prestação 
          de Serviços de Assessoria Consultiva de Inglês, que se regerá pelas cláusulas seguintes e pelas 
          condições descritas no presente.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA PRIMEIRA – DO OBJETO</h2>
        <p style="text-align: justify;">
          1.1. O presente contrato tem como objeto a prestação de serviços de assessoria consultiva para 
          o aprendizado da língua inglesa, por meio de acompanhamento personalizado, sessões individuais 
          e/ou em grupo, conforme especificado no ANEXO I deste contrato.
        </p>
        <p style="text-align: justify;">
          1.2. A metodologia utilizada pela CONTRATADA é baseada em abordagem comunicativa, com foco no 
          desenvolvimento das habilidades linguísticas necessárias para os objetivos específicos do CONTRATANTE.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA SEGUNDA – DO PRAZO</h2>
        <p style="text-align: justify;">
          2.1. O presente contrato terá duração de {{plan_duration}}, com início na data da assinatura 
          deste instrumento.
        </p>
        <p style="text-align: justify;">
          2.2. O contrato poderá ser renovado mediante acordo entre as partes, por meio de termo aditivo.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA TERCEIRA – DO VALOR E FORMA DE PAGAMENTO</h2>
        <p style="text-align: justify;">
          3.1. Pela prestação dos serviços descritos neste contrato, o CONTRATANTE pagará à CONTRATADA 
          o valor total de R$ {{plan_value}} ({{plan_value}} reais).
        </p>
        <p style="text-align: justify;">
          3.2. O pagamento será realizado em {{installments_count}} parcelas, com vencimento todo dia 
          {{installment_due_day}} de cada mês.
        </p>
        <p style="text-align: justify;">
          3.3. O atraso no pagamento de qualquer parcela implicará em multa de 2% (dois por cento) sobre 
          o valor da parcela em atraso, além de juros de mora de 1% (um por cento) ao mês.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA QUARTA – DAS OBRIGAÇÕES DA CONTRATADA</h2>
        <p style="text-align: justify;">
          4.1. Prestar os serviços de assessoria consultiva de forma profissional e ética.<br>
          4.2. Disponibilizar material didático adequado aos objetivos do CONTRATANTE.<br>
          4.3. Respeitar os horários agendados para as sessões.<br>
          4.4. Manter sigilo sobre as informações pessoais do CONTRATANTE.<br>
          4.5. Fornecer relatórios de progresso quando solicitado.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA QUINTA – DAS OBRIGAÇÕES DO CONTRATANTE</h2>
        <p style="text-align: justify;">
          5.1. Efetuar os pagamentos nas datas acordadas.<br>
          5.2. Comparecer às sessões agendadas ou comunicar ausência com antecedência mínima de 24 horas.<br>
          5.3. Dedicar-se aos estudos e atividades propostas.<br>
          5.4. Respeitar as normas e orientações da CONTRATADA.<br>
          5.5. Informar qualquer alteração em seus dados cadastrais.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA SEXTA – DA RESCISÃO</h2>
        <p style="text-align: justify;">
          6.1. O presente contrato poderá ser rescindido por qualquer das partes, mediante comunicação 
          por escrito com antecedência mínima de 30 (trinta) dias.
        </p>
        <p style="text-align: justify;">
          6.2. Em caso de rescisão por iniciativa do CONTRATANTE, será devido o pagamento proporcional 
          aos serviços já prestados, acrescido de multa de 10% (dez por cento) sobre o valor restante do contrato.
        </p>
        <p style="text-align: justify;">
          6.3. A CONTRATADA poderá rescindir o contrato de pleno direito em caso de inadimplência superior 
          a 30 (trinta) dias ou descumprimento de qualquer cláusula contratual pelo CONTRATANTE.
        </p>

        <h2 style="color: #8B0000; font-size: 14pt; margin-top: 25px;">CLÁUSULA SÉTIMA – DO FORO</h2>
        <p style="text-align: justify;">
          7.1. As partes elegem o foro da Comarca de Guarulhos/SP para dirimir quaisquer dúvidas ou 
          controvérsias oriundas deste contrato, renunciando a qualquer outro, por mais privilegiado que seja.
        </p>

        <p style="text-align: justify; margin-top: 30px;">
          E por estarem assim justas e contratadas, as partes assinam o presente instrumento em via digital, 
          com validade jurídica conforme a Lei nº 14.620/2023 e o artigo 784, §4º do Código de Processo Civil.
        </p>

        <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #8B0000;">
          <h2 style="color: #8B0000; font-size: 14pt; text-align: center;">ANEXO I – ESPECIFICAÇÃO DO PLANO</h2>
          
          <table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold; width: 200px;">Plano:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{plan_name}}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Duração:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{plan_duration}}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Call Estratégica:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{sessions_call_estrategica}} sessão(ões)</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Sessões Individuais:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{sessions_individual}} sessão(ões)</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Sessões Consultivas em Grupo:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{sessions_group_consultive}} sessão(ões)</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Encontros em Grupo:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{sessions_group_meetings}} encontro(s)</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Valor Total:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">R$ {{plan_value}}</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Parcelas:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">{{installments_count}}x</td>
            </tr>
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd; background-color: #f5f5f5; font-weight: bold;">Dia de Vencimento:</td>
              <td style="padding: 8px; border: 1px solid #ddd;">Todo dia {{installment_due_day}}</td>
            </tr>
          </table>
        </div>
      </div>
    HTML
  end
end
