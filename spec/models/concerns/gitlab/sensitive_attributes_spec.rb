# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SensitiveAttributes, feature_category: :shared do
  describe '.sensitive_attributes' do
    context 'for models using attr_encrypted' do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include Gitlab::SensitiveAttributes

          self.table_name = :web_hooks

          attr_encrypted :token,
            mode: :per_attribute_iv,
            algorithm: 'aes-256-gcm',
            key: SecureRandom.hex

          def self.name
            'TestClass'
          end
        end
      end

      it 'includes attr_encrypted attributes' do
        klass = test_class

        expect(klass.sensitive_attributes).to contain_exactly(:token, :encrypted_token, :encrypted_token_iv)
      end
    end

    context 'for models using TokenAuthenticatable' do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include Gitlab::SensitiveAttributes
          include TokenAuthenticatable

          self.table_name = :ci_runners

          add_authentication_token_field :token, encrypted: :optional

          def self.name
            'TestClass'
          end
        end
      end

      it 'includes TokenAuthenticatable attributes' do
        klass = test_class

        expect(klass.sensitive_attributes).to contain_exactly(:token, :token_encrypted)
      end
    end
  end
end
