# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../support/shared_contexts/lib/sbom/package_url_shared_contexts'

RSpec.describe Sbom::PackageUrl::Normalizer, feature_category: :dependency_management do
  shared_examples 'name normalization' do
    context 'with bitbucket url' do
      let(:type) { 'bitbucket' }
      let(:text) { 'Purl_Spec' }

      it 'downcases text' do
        is_expected.to eq('purl_spec')
      end
    end

    context 'with github url' do
      let(:type) { 'github' }
      let(:text) { 'Purl_Spec' }

      it 'downcases text' do
        is_expected.to eq('purl_spec')
      end
    end

    context 'with golang url' do
      let(:type) { 'golang' }
      let(:text) { 'github.com/Docker/docker' }

      it 'downcases text' do
        is_expected.to eq('github.com/docker/docker')
      end
    end

    context 'with pypi url' do
      let(:type) { 'pypi' }

      %w[Purl_Spec Purl.Spec Purl-Spec Purl--Spec].each do |input_text|
        context "and based on #{described_class::PYPI_REGEX}" do
          let(:text) { input_text }

          it { is_expected.to eq 'purl-spec' }
        end
      end

      %w[purl-spec purlspec].each do |input_text|
        context "and not based on #{described_class::PYPI_REGEX}" do
          let(:text) { input_text }

          it { is_expected.to eq input_text }
        end
      end
    end

    context 'with other urls' do
      let(:type) { 'npm' }
      let(:text) { 'Purl_Spec' }

      it 'does not change the text' do
        is_expected.to eq(text)
      end
    end
  end

  describe '#normalize_name' do
    subject(:normalize_name) { described_class.new(type: type, text: text).normalize_name }

    it_behaves_like 'name normalization'

    context 'when text is nil' do
      let(:type) { 'npm' }
      let(:text) { nil }

      it 'raises an error' do
        expect { normalize_name }.to raise_error(ArgumentError, 'Name is required')
      end
    end
  end

  describe '#normalize_namespace' do
    subject(:normalize_namespace) { described_class.new(type: type, text: text).normalize_namespace }

    it_behaves_like 'name normalization'

    context 'when text is nil' do
      let(:type) { 'npm' }
      let(:text) { nil }

      it 'allows nil values' do
        expect(normalize_namespace).to be_nil
      end
    end
  end
end
