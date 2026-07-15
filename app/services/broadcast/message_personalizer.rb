# frozen_string_literal: true

# Resolve spintax ({a|b|c}) e placeholders ({primeiro_nome}, {nome}, {merge1}...)
# para gerar uma mensagem levemente diferente por contato, sem mudar o contexto.
module Broadcast
  class MessagePersonalizer
    SPINTAX = /\{([^{}]*\|[^{}]*)\}/

    def initialize(template, recipient)
      @template = template.to_s
      @recipient = recipient
    end

    def call
      apply_merge_fields(resolve_spintax(@template))
    end

    private

    def resolve_spintax(text)
      text.gsub(SPINTAX) do
        Regexp.last_match(1).split('|').sample
      end
    end

    def apply_merge_fields(text)
      text = text.gsub('{primeiro_nome}', first_name)
                 .gsub('{nome}', @recipient.name.to_s)
      (@recipient.merge_fields || {}).each do |key, value|
        text = text.gsub("{#{key}}", value.to_s)
      end
      text
    end

    def first_name
      @recipient.name.to_s.strip.split(/\s+/).first.to_s
    end
  end
end
