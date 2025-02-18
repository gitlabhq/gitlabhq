# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeviseEmailValidator do
  let!(:user) { build(:user, public_email: 'test@example.com') }

  subject(:validate) { validator.validate(user) }

  describe 'validations' do
    context 'by default' do
      let(:validator) { described_class.new(attributes: [:public_email]) }

      it 'allows when email is valid' do
        validate

        expect(user.errors).to be_empty
      end

      it 'returns error when email is invalid' do
        user.public_email = 'invalid'

        validate

        expect(user.errors).to be_present
        expect(user.errors.added?(:public_email)).to be true
      end

      it 'returns error when email is nil' do
        user.public_email = nil

        validate

        expect(user.errors).to be_present
      end

      it 'returns error when email is blank' do
        user.public_email = ''

        validate

        expect(user.errors).to be_present
        expect(user.errors.added?(:public_email)).to be true
      end

      context 'for email with encoded-word' do
        %w[
          test=?invalidcharacter?=@example.com
          user+company=?example?=@example.com
          =?iso-8859-1?q?testencodedformat=40new.example.com=3e=20?=testencodedformat@example.com
          =?iso-8859-1?q?testencodedformat=40new.example.com?=testencodedformat@example.com
        ].each do |invalid_email|
          it "returns error as invalid email for '#{invalid_email}'" do
            user.public_email = invalid_email

            validate

            expect(user.errors).to be_present
            expect(user.errors.added?(:public_email)).to be true
          end
        end
      end
    end
  end

  context 'when regexp is set as Regexp' do
    let(:validator) { described_class.new(attributes: [:public_email], regexp: /[0-9]/) }

    it 'allows when value match' do
      user.public_email = '1'

      validate

      expect(user.errors).to be_empty
    end

    it 'returns error when value does not match' do
      validate

      expect(user.errors).to be_present
    end
  end

  context 'when regexp is set as String' do
    it 'raise argument error' do
      expect { described_class.new({ regexp: 'something' }) }.to raise_error ArgumentError
    end
  end

  context 'when allow_nil is set to true' do
    let(:validator) { described_class.new(attributes: [:public_email], allow_nil: true) }

    it 'allows when email is nil' do
      user.public_email = nil

      validate

      expect(user.errors).to be_empty
    end
  end

  context 'when allow_blank is set to true' do
    let(:validator) { described_class.new(attributes: [:public_email], allow_blank: true) }

    it 'allows when email is blank' do
      user.public_email = ''

      validate

      expect(user.errors).to be_empty
    end
  end

  context 'when attribute is already marked invalid' do
    let(:validator) { described_class.new(attributes: [:email]) }

    it 'does not add duplicate error' do
      user.email = 'Invalid as per Devise::Models::Validatable'
      user.validate

      validate

      expect(user.errors[:email].size).to eq 1
    end
  end
end
