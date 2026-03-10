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
            <td style="padding: 8px; border: 1px solid #ddd;">{{
