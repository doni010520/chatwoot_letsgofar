# frozen_string_literal: true

require 'csv'

# Parseia o CSV enviado pelo usuário (telefone, nome, merge1, merge2, ...)
# em atributos de BroadcastRecipient. Telefone vira só dígitos (E.164 sem +).
module Broadcast
  class ContactListParser
    RESERVED = %w[telefone nome].freeze

    def initialize(file)
      @file = file
    end

    def parse
      rows = []
      CSV.foreach(@file.path, headers: true, header_converters: :downcase, encoding: 'bom|utf-8') do |row|
        phone = normalize_phone(row['telefone'])
        next if phone.blank?

        rows << {
          phone: phone,
          name: row['nome'].to_s.strip,
          merge_fields: extra_fields(row)
        }
      end
      rows
    end

    private

    def normalize_phone(raw)
      digits = raw.to_s.gsub(/\D/, '')
      return nil if digits.length < 10

      # Se veio sem DDI (10 ou 11 dígitos = número BR sem 55), completa com 55.
      digits = "55#{digits}" if digits.length <= 11
      digits
    end

    def extra_fields(row)
      fields = {}
      row.headers.compact.each do |header|
        next if RESERVED.include?(header)

        value = row[header]
        fields[header] = value if value.present?
      end
      fields
    end
  end
end
