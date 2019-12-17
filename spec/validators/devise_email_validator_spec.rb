# frozen_string_literal: true

require 'spec_helper'

describe DeviseEmailValidator do
  let!(:user) { build(:user, public_email: 'test@example.com') }

  subject { validator.validate(user) }

  describe 'validations' do
    context 'by default' do
      let(:validator) { described_class.new(attributes: [:public_email]) }

      it 'allows when email is valid' do
        subject

        expect(user.errors).to be_empty
      end

      it 'returns error when email is invalid' do
        user.public_email = 'invalid'

        subject

        expect(user.errors).to be_present
        expect(user.errors.first[1]).to eq 'is invalid'
      end

      it 'returns error when email is nil' do
        user.public_email = nil

        subject

        expect(user.errors).to be_present
      end

      it 'returns error when email is blank' do
        user.public_email = ''

        subject

        expect(user.errors).to be_present
        expect(user.errors.first[1]).to eq 'is invalid'
      end
    end
  end

  context 'when regexp is set as Regexp' do
    let(:validator) { described_class.new(attributes: [:public_email], regexp: /[0-9]/) }

    it 'allows when value match' do
      user.public_email = '1'

      subject

      expect(user.errors).to be_empty
    end

    it 'returns error when value does not match' do
      subject

      expect(user.errors).to be_present
    end
  end

  context 'when regexp is set as String' do
    it 'raise argument error' do
      expect { described_class.new( { regexp: 'something' } ) }.to raise_error ArgumentError
    end
  end

  context 'when allow_nil is set to true' do
    let(:validator) { described_class.new(attributes: [:public_email], allow_nil: true) }

    it 'allows when email is nil' do
      user.public_email = nil

      subject

      expect(user.errors).to be_empty
    end
  end

  context 'when allow_blank is set to true' do
    let(:validator) { described_class.new(attributes: [:public_email], allow_blank: true) }

    it 'allows when email is blank' do
      user.public_email = ''

      subject

      expect(user.errors).to be_empty
    end
  end
end
