# app/jobs/kanban_webhook_job.rb
class KanbanWebhookJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(url:, method:, headers:, body:, conversation_id:)
    Rails.logger.info "[KanbanWebhookJob] Sending #{method} to #{url} for conversation ##{conversation_id}"

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30

    request = build_request(uri, method, headers, body)
    response = http.request(request)

    if response.code.to_i >= 400
      Rails.logger.error "[KanbanWebhookJob] Failed with status #{response.code}: #{response.body}"
      raise "Webhook failed with status #{response.code}"
    end

    Rails.logger.info "[KanbanWebhookJob] Success - Status: #{response.code}"
  end

  private

  def build_request(uri, method, headers, body)
    case method.to_s.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri.request_uri)
    when 'PUT'
      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = body
    else # POST
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = body
    end

    headers.each { |key, value| request[key] = value }
    request
  end
end
