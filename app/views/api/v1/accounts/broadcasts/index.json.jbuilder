# frozen_string_literal: true

json.array! @broadcasts, partial: 'api/v1/accounts/broadcasts/broadcast', as: :broadcast
