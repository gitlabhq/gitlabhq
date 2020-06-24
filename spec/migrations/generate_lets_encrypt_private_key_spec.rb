# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20190524062810_generate_lets_encrypt_private_key.rb')

RSpec.describe GenerateLetsEncryptPrivateKey do
  describe '#up' do
    it 'does not fail' do
      expect do
        described_class.new.up
      end.not_to raise_error
    end
  end
end
