# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers do
  describe '.fabricate!' do
    subject { described_class.fabricate!(file_type) }

    context 'when file_type is junit' do
      let(:file_type) { 'junit' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Test::Junit)
      end
    end

    context 'when file_type is cobertura' do
      let(:file_type) { 'cobertura' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Coverage::Cobertura)
      end
    end

    context 'when file_type is jacoco' do
      let(:file_type) { 'jacoco' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Coverage::Jacoco)
      end
    end

    context 'when file_type is accessibility' do
      let(:file_type) { 'accessibility' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Accessibility::Pa11y)
      end
    end

    context 'when file_type is codequality' do
      let(:file_type) { 'codequality' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Codequality::CodeClimate)
      end
    end

    context 'when file_type is terraform' do
      let(:file_type) { 'terraform' }

      it 'fabricates the class' do
        is_expected.to be_a(described_class::Terraform::Tfplan)
      end
    end

    context 'when file_type does not exist' do
      let(:file_type) { 'undefined' }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Ci::Parsers::ParserNotFoundError)
      end
    end
  end

  describe '.instrument!' do
    it 'prepends the Instrumentation module into each parser' do
      expect(described_class.parsers.values).to all(receive(:prepend).with(Gitlab::Ci::Parsers::Instrumentation))

      described_class.instrument!
    end
  end
end
