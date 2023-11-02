# frozen_string_literal: true

module CryptoHelpers
  def sha256(value)
    Gitlab::CryptoHelper.sha256(value)
  end
end
