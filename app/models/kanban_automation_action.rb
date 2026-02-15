# app/models/kanban_automation_action.rb
class KanbanAutomationAction < ApplicationRecord
  # Associations
  belongs_to :kanban_automation

  # Validations
  validates :action_type, presence: true, inclusion: { in: %w[
    move_to_stage
    assign_user
    send_webhook
    send_email
    send_whatsapp_template
    create_task
    add_label
    remove_label
    update_custom_field
    update_deal_value
    add_note
    mark_won
    mark_lost
  ] }

  # Scopes
  scope :ordered, -> { order(position: :asc) }

  # Action types with descriptions
  ACTION_TYPES = {
    'move_to_stage' => {
      name: 'Mover para Estágio',
      description: 'Move a conversa para outro estágio',
      config_fields: [
        { key: 'stage_id', label: 'Estágio', type: 'select', source: 'stages', required: true }
      ]
    },
    'assign_user' => {
      name: 'Atribuir Responsável',
      description: 'Atribui a conversa a um usuário',
      config_fields: [
        { key: 'user_id', label: 'Usuário', type: 'select', source: 'users', required: true }
      ]
    },
    'send_webhook' => {
      name: 'Enviar Webhook',
      description: 'Envia um POST/GET para uma URL externa',
      config_fields: [
        { key: 'url', label: 'URL', type: 'text', required: true },
        { key: 'method', label: 'Método', type: 'select', options: %w[POST GET PUT], required: true },
        { key: 'headers', label: 'Headers (JSON)', type: 'textarea', required: false },
        { key: 'body_template', label: 'Body Template', type: 'textarea', required: false }
      ]
    },
    'send_email' => {
      name: 'Enviar Email',
      description: 'Envia um email para o contato ou endereço específico',
      config_fields: [
        { key: 'to', label: 'Para (vazio = contato)', type: 'text', required: false },
        { key: 'subject_template', label: 'Assunto', type: 'text', required: true },
        { key: 'body_template', label: 'Corpo do Email', type: 'textarea', required: true }
      ]
    },
    'send_whatsapp_template' => {
      name: 'Enviar Template WhatsApp',
      description: 'Envia um template aprovado via WhatsApp',
      config_fields: [
        { key: 'inbox_id', label: 'Inbox WhatsApp', type: 'select', source: 'whatsapp_inboxes', required: true },
        { key: 'template_name', label: 'Nome do Template', type: 'text', required: true },
        { key: 'template_params', label: 'Parâmetros (JSON)', type: 'textarea', required: false }
      ]
    },
    'create_task' => {
      name: 'Criar Tarefa',
      description: 'Cria uma tarefa automaticamente',
      config_fields: [
        { key: 'title_template', label: 'Título', type: 'text', required: true },
        { key: 'description_template', label: 'Descrição', type: 'textarea', required: false },
        { key: 'due_in_hours', label: 'Vencimento em (horas)', type: 'number', required: false },
        { key: 'priority', label: 'Prioridade', type: 'select', options: %w[low medium high urgent], required: false },
        { key: 'assign_to', label: 'Atribuir a', type: 'select', source: 'users', required: false }
      ]
    },
    'add_label' => {
      name: 'Adicionar Label',
      description: 'Adiciona uma label à conversa',
      config_fields: [
        { key: 'label_id', label: 'Label', type: 'select', source: 'labels', required: true }
      ]
    },
    'remove_label' => {
      name: 'Remover Label',
      description: 'Remove uma label da conversa',
      config_fields: [
        { key: 'label_id', label: 'Label', type: 'select', source: 'labels', required: true }
      ]
    },
    'update_custom_field' => {
      name: 'Atualizar Campo',
      description: 'Atualiza um campo personalizado',
      config_fields: [
        { key: 'field_key', label: 'Campo', type: 'select', source: 'custom_fields', required: true },
        { key: 'value_template', label: 'Valor', type: 'text', required: true }
      ]
    },
    'update_deal_value' => {
      name: 'Atualizar Valor',
      description: 'Atualiza o valor do negócio',
      config_fields: [
        { key: 'value', label: 'Valor Fixo', type: 'number', required: false },
        { key: 'formula', label: 'Fórmula (ex: +1000, *1.1)', type: 'text', required: false }
      ]
    },
    'add_note' => {
      name: 'Adicionar Nota',
      description: 'Adiciona uma nota ao histórico',
      config_fields: [
        { key: 'note_template', label: 'Conteúdo da Nota', type: 'textarea', required: true }
      ]
    },
    'mark_won' => {
      name: 'Marcar como Ganho',
      description: 'Marca o negócio como ganho',
      config_fields: []
    },
    'mark_lost' => {
      name: 'Marcar como Perdido',
      description: 'Marca o negócio como perdido',
      config_fields: [
        { key: 'reason', label: 'Motivo', type: 'text', required: false }
      ]
    }
  }.freeze

  def self.action_types_for_select
    ACTION_TYPES.map do |key, value|
      {
        value: key,
        label: value[:name],
        description: value[:description],
        config_fields: value[:config_fields]
      }
    end
  end

  def action_info
    ACTION_TYPES[action_type] || {}
  end

  def config_fields
    action_info[:config_fields] || []
  end

  # Execute the action
  def execute(conversation, event_data = {}, current_user = nil)
    case action_type
    when 'move_to_stage'
      execute_move_to_stage(conversation)
    when 'assign_user'
      execute_assign_user(conversation)
    when 'send_webhook'
      execute_send_webhook(conversation, event_data)
    when 'send_email'
      execute_send_email(conversation, event_data)
    when 'send_whatsapp_template'
      execute_send_whatsapp(conversation, event_data)
    when 'create_task'
      execute_create_task(conversation, current_user)
    when 'add_label'
      execute_add_label(conversation)
    when 'remove_label'
      execute_remove_label(conversation)
    when 'update_custom_field'
      execute_update_custom_field(conversation, event_data)
    when 'update_deal_value'
      execute_update_deal_value(conversation)
    when 'add_note'
      execute_add_note(conversation, event_data, current_user)
    when 'mark_won'
      execute_mark_won(conversation)
    when 'mark_lost'
      execute_mark_lost(conversation)
    else
      { success: false, error: "Unknown action type: #{action_type}" }
    end
  end

  private

  def execute_move_to_stage(conversation)
    stage_id = action_config['stage_id']
    return { success: false, error: 'Stage ID not configured' } if stage_id.blank?

    conversation.update(kanban_stage_id: stage_id)
    { success: true, action: 'move_to_stage', stage_id: stage_id }
  end

  def execute_assign_user(conversation)
    user_id = action_config['user_id']
    return { success: false, error: 'User ID not configured' } if user_id.blank?

    conversation.update(assignee_id: user_id)
    { success: true, action: 'assign_user', user_id: user_id }
  end

  def execute_send_webhook(conversation, event_data)
    url = action_config['url']
    return { success: false, error: 'URL not configured' } if url.blank?

    method = action_config['method'] || 'POST'
    headers = parse_json(action_config['headers']) || { 'Content-Type' => 'application/json' }
    body_template = action_config['body_template'] || default_webhook_body

    body = render_template(body_template, conversation, event_data)

    # Execute webhook asynchronously
    KanbanWebhookJob.perform_later(
      url: url,
      method: method,
      headers: headers,
      body: body,
      conversation_id: conversation.id
    )

    { success: true, action: 'send_webhook', url: url }
  end

  def execute_send_email(conversation, event_data)
    to = action_config['to'].presence || conversation.contact&.email
    return { success: false, error: 'No email address' } if to.blank?

    subject = render_template(action_config['subject_template'], conversation, event_data)
    body = render_template(action_config['body_template'], conversation, event_data)

    # Use Chatwoot's mailer or custom implementation
    KanbanMailer.automation_email(to: to, subject: subject, body: body).deliver_later

    { success: true, action: 'send_email', to: to }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def execute_send_whatsapp(conversation, event_data)
    inbox_id = action_config['inbox_id']
    template_name = action_config['template_name']

    return { success: false, error: 'Inbox or template not configured' } if inbox_id.blank? || template_name.blank?

    template_params = parse_json(action_config['template_params']) || []

    # Render template params
    rendered_params = template_params.map do |param|
      render_template(param, conversation, event_data)
    end

    # Queue WhatsApp template message
    KanbanWhatsappTemplateJob.perform_later(
      conversation_id: conversation.id,
      inbox_id: inbox_id,
      template_name: template_name,
      template_params: rendered_params
    )

    { success: true, action: 'send_whatsapp_template', template: template_name }
  end

  def execute_create_task(conversation, current_user)
    title = action_config['title_template'] || 'Tarefa automática'
    description = action_config['description_template']
    due_in_hours = action_config['due_in_hours'].to_i
    priority = action_config['priority'] || 'medium'
    assign_to = action_config['assign_to']

    task = conversation.kanban_tasks.create!(
      account_id: conversation.account_id,
      user_id: current_user&.id || conversation.assignee_id,
      assigned_to_id: assign_to.presence || conversation.assignee_id,
      title: title,
      description: description,
      priority: priority,
      due_at: due_in_hours.positive? ? Time.current + due_in_hours.hours : nil
    )

    { success: true, action: 'create_task', task_id: task.id }
  end

  def execute_add_label(conversation)
    label_id = action_config['label_id']
    return { success: false, error: 'Label ID not configured' } if label_id.blank?

    label = conversation.account.labels.find_by(id: label_id)
    return { success: false, error: 'Label not found' } unless label

    conversation.labels << label unless conversation.labels.include?(label)
    { success: true, action: 'add_label', label_id: label_id }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def execute_remove_label(conversation)
    label_id = action_config['label_id']
    return { success: false, error: 'Label ID not configured' } if label_id.blank?

    conversation.labels.delete(Label.find_by(id: label_id))
    { success: true, action: 'remove_label', label_id: label_id }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def execute_update_custom_field(conversation, event_data)
    field_key = action_config['field_key']
    value_template = action_config['value_template']

    return { success: false, error: 'Field key not configured' } if field_key.blank?

    pipeline = conversation.kanban_stage&.kanban_pipeline
    return { success: false, error: 'Pipeline not found' } unless pipeline

    custom_field = pipeline.kanban_custom_fields.find_by(field_key: field_key)
    return { success: false, error: 'Custom field not found' } unless custom_field

    value = render_template(value_template, conversation, event_data)

    field_value = conversation.kanban_custom_field_values.find_or_initialize_by(
      kanban_custom_field_id: custom_field.id
    )
    field_value.update!(value: value)

    { success: true, action: 'update_custom_field', field_key: field_key, value: value }
  end

  def execute_update_deal_value(conversation)
    fixed_value = action_config['value']
    formula = action_config['formula']

    new_value = if fixed_value.present?
                  fixed_value.to_f
                elsif formula.present?
                  calculate_formula(conversation.deal_value.to_f, formula)
                else
                  return { success: false, error: 'No value or formula configured' }
                end

    conversation.update(deal_value: new_value)
    { success: true, action: 'update_deal_value', value: new_value }
  end

  def execute_add_note(conversation, event_data, current_user)
    note_template = action_config['note_template']
    return { success: false, error: 'Note template not configured' } if note_template.blank?

    note = render_template(note_template, conversation, event_data)

    conversation.kanban_activities.create!(
      account_id: conversation.account_id,
      user_id: current_user&.id,
      activity_type: 'note_added',
      title: 'Nota automática',
      description: note,
      metadata: { automated: true, automation_id: kanban_automation_id }
    )

    { success: true, action: 'add_note' }
  end

  def execute_mark_won(conversation)
    conversation.update(
      closed_won: true,
      closed_at: Time.current
    )
    { success: true, action: 'mark_won' }
  end

  def execute_mark_lost(conversation)
    reason = action_config['reason']
    conversation.update(
      closed_won: false,
      closed_reason: reason,
      closed_at: Time.current
    )
    { success: true, action: 'mark_lost', reason: reason }
  end

  # Helper methods
  def render_template(template, conversation, event_data)
    return template if template.blank?

    result = template.dup
    contact = conversation.contact
    assignee = conversation.assignee
    stage = conversation.kanban_stage

    # Contact variables
    result.gsub!('{{contact.name}}', contact&.name.to_s)
    result.gsub!('{{contact.email}}', contact&.email.to_s)
    result.gsub!('{{contact.phone}}', contact&.phone_number.to_s)

    # Conversation variables
    result.gsub!('{{conversation.id}}', conversation.id.to_s)
    result.gsub!('{{conversation.display_id}}', conversation.display_id.to_s)

    # Deal variables
    result.gsub!('{{deal.value}}', conversation.deal_value.to_s)
    result.gsub!('{{deal.stage}}', stage&.name.to_s)

    # Assignee variables
    result.gsub!('{{assignee.name}}', assignee&.name.to_s)
    result.gsub!('{{assignee.email}}', assignee&.email.to_s)

    # Event variables
    result.gsub!('{{trigger.from_stage}}', event_data[:from_stage_name].to_s)
    result.gsub!('{{trigger.to_stage}}', event_data[:to_stage_name].to_s)
    result.gsub!('{{trigger.old_value}}', event_data[:old_value].to_s)
    result.gsub!('{{trigger.new_value}}', event_data[:new_value].to_s)

    # Custom fields
    conversation.kanban_custom_field_values.includes(:kanban_custom_field).each do |cfv|
      result.gsub!("{{custom_fields.#{cfv.kanban_custom_field.field_key}}}", cfv.value.to_s)
    end

    result
  end

  def parse_json(json_string)
    return nil if json_string.blank?

    JSON.parse(json_string)
  rescue JSON::ParserError
    nil
  end

  def calculate_formula(current_value, formula)
    # Simple formula support: +X, -X, *X, /X
    case formula[0]
    when '+'
      current_value + formula[1..].to_f
    when '-'
      current_value - formula[1..].to_f
    when '*'
      current_value * formula[1..].to_f
    when '/'
      divisor = formula[1..].to_f
      divisor.zero? ? current_value : current_value / divisor
    else
      formula.to_f
    end
  end

  def default_webhook_body
    {
      conversation_id: '{{conversation.id}}',
      contact_name: '{{contact.name}}',
      contact_email: '{{contact.email}}',
      deal_value: '{{deal.value}}',
      stage: '{{deal.stage}}'
    }.to_json
  end
end
