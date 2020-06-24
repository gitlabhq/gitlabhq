# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamedEcdsaKeyValidator do
  let(:validator) { described_class.new(attributes: [:key]) }
  let!(:domain) { build(:pages_domain) }

  subject { validator.validate_each(domain, :key, value) }

  context 'with empty value' do
    let(:value) { nil }

    it 'does not add any error if value is empty' do
      subject

      expect(domain.errors).to be_empty
    end
  end

  shared_examples 'does not add any error' do
    it 'does not add any error' do
      expect(value).to be_present

      subject

      expect(domain.errors).to be_empty
    end
  end

  context 'when key is not EC' do
    let(:value) { attributes_for(:pages_domain)[:key] }

    include_examples 'does not add any error'
  end

  context 'with ECDSA certificate with named curve' do
    let(:value) { attributes_for(:pages_domain, :ecdsa)[:key] }

    include_examples 'does not add any error'
  end

  context 'with ECDSA certificate with explicit curve params' do
    let(:value) { attributes_for(:pages_domain, :explicit_ecdsa)[:key] }

    it 'adds errors' do
      expect(value).to be_present

      subject

      expect(domain.errors[:key]).not_to be_empty
    end
  end
end
