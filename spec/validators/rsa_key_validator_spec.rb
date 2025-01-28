# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RsaKeyValidator do
  let(:validatable) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :signing_key

      validates :signing_key, rsa_key: true

      def initialize(signing_key)
        @signing_key = signing_key
      end
    end
  end

  subject(:validator) { described_class.new(attributes: [:signing_key]) }

  it 'is not valid when invalid RSA key is provided' do
    record = validatable.new('invalid RSA key')

    validator.validate(record)

    aggregate_failures do
      expect(record).not_to be_valid
      expect(record.errors[:signing_key]).to include('is not a valid RSA key')
    end
  end

  it 'is valid when valid RSA key is provided' do
    record = validatable.new(OpenSSL::PKey::RSA.new(1024).to_pem)

    validator.validate(record)

    expect(record).to be_valid
  end
end
