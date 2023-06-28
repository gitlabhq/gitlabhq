# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Metadata, feature_category: :source_code_management do
  subject(:attributes) do
    described_class.new(
      cache_identifier: cache_identifier,
      feature_category: feature_category,
      backing_resource: backing_resource
    )
  end

  let(:cache_identifier) { 'ApplicationController#show' }
  let(:feature_category) { :source_code_management }
  let(:backing_resource) { :unknown }

  describe '#initialize' do
    context 'when optional arguments are not set' do
      it 'sets default value for them' do
        attributes = described_class.new

        expect(attributes.feature_category).to eq(:not_owned)
        expect(attributes.backing_resource).to eq(:unknown)
        expect(attributes.cache_identifier).to be_nil
      end
    end

    context 'when invalid feature category is set' do
      let(:feature_category) { :not_supported }

      it { expect { attributes }.to raise_error(RuntimeError) }

      context 'when on production' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it 'does not raise an exception' do
          expect { attributes }.not_to raise_error
          expect(attributes.feature_category).to eq('unknown')
        end
      end
    end

    context 'when not_owned feature category is set' do
      let(:feature_category) { :not_owned }

      it { expect(attributes.feature_category).to eq(:not_owned) }
    end

    context 'when backing resource is not supported' do
      let(:backing_resource) { 'foo' }

      it { expect { attributes }.to raise_error(RuntimeError) }

      context 'when on production' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it 'does not raise an exception' do
          expect { attributes }.not_to raise_error
        end
      end
    end
  end

  describe '#cache_identifier' do
    subject { attributes.cache_identifier }

    it { is_expected.to eq cache_identifier }
  end

  describe '#feature_category' do
    subject { attributes.feature_category }

    it { is_expected.to eq feature_category }
  end

  describe '#backing_resource' do
    subject { attributes.backing_resource }

    it { is_expected.to eq backing_resource }
  end
end
