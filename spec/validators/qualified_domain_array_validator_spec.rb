# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QualifiedDomainArrayValidator do
  let(:qualified_domain_array_validator_test_class) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :domain_array

      def initialize(domain_array)
        self.domain_array = domain_array
      end
    end
  end

  let!(:record) do
    qualified_domain_array_validator_test_class.new(['gitlab.com'])
  end

  subject { validator.validate(record) }

  shared_examples 'can be nil' do
    it 'allows when attribute is nil' do
      record.domain_array = nil

      subject

      expect(record.errors).to be_empty
    end
  end

  shared_examples 'can be blank' do
    it 'allows when attribute is blank' do
      record.domain_array = []

      subject

      expect(record.errors).to be_empty
    end
  end

  describe 'validations' do
    let(:validator) { described_class.new(attributes: [:domain_array]) }

    it_behaves_like 'can be blank'

    it 'returns error when attribute is nil' do
      record.domain_array = nil

      subject

      expect(record.errors).to be_present
      expect(record.errors.added?(:domain_array, "entries cannot be nil")).to be true
    end

    it 'allows when domain is valid' do
      subject

      expect(record.errors).to be_empty
    end

    it 'returns error when domain contains unicode' do
      record.domain_array = ['ğitlab.com']

      subject

      expect(record.errors).to be_present
      expect(record.errors.added?(:domain_array, 'unicode domains should use IDNA encoding')).to be true
    end

    it 'returns error when entry is larger than 255 chars' do
      record.domain_array = ['a' * 256]

      subject

      expect(record.errors).to be_present
      expect(record.errors.added?(:domain_array, 'entries cannot be larger than 255 characters')).to be true
    end

    it 'returns error when entry contains HTML tags' do
      record.domain_array = ['gitlab.com<h1>something</h1>']

      subject

      expect(record.errors).to be_present
      expect(record.errors.added?(:domain_array, 'entries cannot contain HTML tags')).to be true
    end
  end

  context 'when allow_nil is set to true' do
    let(:validator) { described_class.new(attributes: [:domain_array], allow_nil: true) }

    it_behaves_like 'can be nil'
    it_behaves_like 'can be blank'
  end

  context 'when allow_blank is set to true' do
    let(:validator) { described_class.new(attributes: [:domain_array], allow_blank: true) }

    it_behaves_like 'can be nil'
    it_behaves_like 'can be blank'
  end
end
