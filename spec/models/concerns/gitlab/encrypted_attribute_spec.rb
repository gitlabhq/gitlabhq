# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EncryptedAttribute, feature_category: :shared do
  %i[db_key_base db_key_base_32 db_key_base_truncated].each do |key_method|
    describe "##{key_method}" do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include Gitlab::EncryptedAttribute

          self.table_name = :projects

          attr_encrypted :token, key: key_method

          def self.name
            'Project'
          end
        end
      end

      let(:record) { test_class.new }

      describe key_method do
        context 'when encrypting' do
          before do
            record.attr_encrypted_attributes[:token][:operation] = :encrypting
          end

          it 'returns correct secret' do
            expect(record.__send__(key_method, :token))
              .to eq(Gitlab::Encryption::KeyProvider[key_method].encryption_key.secret)
          end
        end

        context 'when decrypting' do
          before do
            record.attr_encrypted_attributes[:token][:operation] = :decrypting
          end

          it 'returns correct secrets' do
            expect(record.__send__(key_method, :token))
              .to eq(Gitlab::Encryption::KeyProvider[key_method].decryption_keys.map(&:secret))
          end
        end
      end
    end
  end
end
