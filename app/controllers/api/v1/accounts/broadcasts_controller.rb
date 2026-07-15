# frozen_string_literal: true

class Api::V1::Accounts::BroadcastsController < Api::V1::Accounts::BaseController
  before_action :set_broadcast, only: [:show, :update, :destroy, :upload_contacts, :start, :pause, :cancel]

  def index
    @broadcasts = Current.account.broadcast_campaigns.ordered
  end

  def show; end

  def create
    @broadcast = Current.account.broadcast_campaigns.new(broadcast_params)
    @broadcast.user = Current.user
    @broadcast.inbox ||= default_api_inbox

    if @broadcast.save
      render :show, status: :created
    else
      render json: { errors: @broadcast.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @broadcast.update(broadcast_params)
      render :show
    else
      render json: { errors: @broadcast.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @broadcast.destroy!
    head :no_content
  end

  # Recebe o CSV (telefone, nome, merge1, merge2...) e (re)cria os destinatários.
  def upload_contacts
    return render json: { error: 'Arquivo CSV é obrigatório' }, status: :unprocessable_entity if params[:file].blank?

    rows = Broadcast::ContactListParser.new(params[:file]).parse
    return render json: { error: 'Nenhum contato válido no arquivo' }, status: :unprocessable_entity if rows.empty?

    @broadcast.transaction do
      @broadcast.broadcast_recipients.delete_all
      rows.each_with_index do |row, index|
        @broadcast.broadcast_recipients.create!(
          account: Current.account,
          phone: row[:phone],
          name: row[:name],
          merge_fields: row[:merge_fields],
          position: index
        )
      end
    end
    @broadcast.recompute_counts!
    render :show
  end

  # Cria os destinatários a partir de contatos JÁ salvos no Chatwoot
  # (alternativa ao upload de CSV).
  def add_contacts
    ids = Array(params[:contact_ids]).map(&:to_i).uniq
    return render json: { error: 'Selecione ao menos um contato' }, status: :unprocessable_entity if ids.empty?

    contacts = Current.account.contacts.where(id: ids).where.not(phone_number: [nil, ''])
    if contacts.empty?
      return render json: { error: 'Nenhum contato válido (com telefone) selecionado' }, status: :unprocessable_entity
    end

    @broadcast.transaction do
      @broadcast.broadcast_recipients.delete_all
      contacts.each_with_index do |contact, index|
        @broadcast.broadcast_recipients.create!(
          account: Current.account,
          phone: contact.phone_number.to_s.delete('+'),
          name: contact.name,
          position: index
        )
      end
    end
    @broadcast.recompute_counts!
    render :show
  end

  def start
    if @broadcast.broadcast_recipients.pending.none?
      return render json: { error: 'Adicione contatos pendentes antes de iniciar' }, status: :unprocessable_entity
    end

    if @broadcast.start!
      Broadcast::DispatchJob.perform_later(@broadcast.id)
      render :show
    else
      render json: { error: 'Disparo não pode ser iniciado neste status' }, status: :unprocessable_entity
    end
  end

  def pause
    @broadcast.pause!
    render :show
  end

  def cancel
    @broadcast.cancel!
    render :show
  end

  private

  def set_broadcast
    @broadcast = Current.account.broadcast_campaigns.find(params[:id])
  end

  def default_api_inbox
    Current.account.inboxes.find_by(channel_type: 'Channel::Api')
  end

  def broadcast_params
    params.require(:broadcast).permit(
      :title, :message_template, :inbox_id, :min_interval, :max_interval,
      :send_window_start, :send_window_end, :daily_cap
    )
  end
end
