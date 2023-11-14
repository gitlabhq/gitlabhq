# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Environment do
  let(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  context 'when configuration is a string' do
    let(:config) { 'production' }

    describe '#string?' do
      it 'is string configuration' do
        expect(entry).to be_string
      end
    end

    describe '#hash?' do
      it 'is not hash configuration' do
        expect(entry).not_to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to include(name: 'production')
      end
    end

    describe '#name' do
      it 'returns environment name' do
        expect(entry.name).to eq 'production'
      end
    end

    describe '#url' do
      it 'returns environment url' do
        expect(entry.url).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    let(:config) do
      { name: 'development', url: 'https://example.gitlab.com' }
    end

    describe '#string?' do
      it 'is not string configuration' do
        expect(entry).not_to be_string
      end
    end

    describe '#hash?' do
      it 'is hash configuration' do
        expect(entry).to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to eq config
      end
    end

    describe '#name' do
      it 'returns environment name' do
        expect(entry.name).to eq 'development'
      end
    end

    describe '#url' do
      it 'returns environment url' do
        expect(entry.url).to eq 'https://example.gitlab.com'
      end
    end
  end

  context 'when valid action is used' do
    where(:action) do
      %w[start stop prepare verify access]
    end

    with_them do
      let(:config) do
        { name: 'production', action: action }
      end

      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when wrong action type is used' do
    let(:config) do
      { name: 'production',
        action: ['stop'] }
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    describe '#errors' do
      it 'contains error about wrong action type' do
        expect(entry.errors)
          .to include 'environment action should be a string'
      end
    end
  end

  context 'when invalid action is used' do
    let(:config) do
      { name: 'production',
        action: 'invalid' }
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    describe '#errors' do
      it 'contains error about invalid action' do
        expect(entry.errors)
          .to include 'environment action should be start, stop, prepare, verify, or access'
      end
    end
  end

  context 'when on_stop is used' do
    let(:config) do
      { name: 'production',
        on_stop: 'close_app' }
    end

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'when invalid on_stop is used' do
    let(:config) do
      { name: 'production',
        on_stop: false }
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    describe '#errors' do
      it 'contains error about invalid action' do
        expect(entry.errors)
          .to include 'environment on stop should be a string'
      end
    end
  end

  context 'when wrong url type is used' do
    let(:config) do
      { name: 'production',
        url: ['https://meow.meow'] }
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    describe '#errors' do
      it 'contains error about wrong url type' do
        expect(entry.errors)
          .to include 'environment url should be a string'
      end
    end
  end

  context 'when variables are used for environment' do
    let(:config) do
      { name: 'review/$CI_COMMIT_REF_NAME',
        url: 'https://$CI_COMMIT_REF_NAME.review.gitlab.com' }
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when auto_stop_in is specified' do
    let(:config) do
      {
        name: 'review/$CI_COMMIT_REF_NAME',
        url: 'https://$CI_COMMIT_REF_NAME.review.gitlab.com',
        on_stop: 'stop_review',
        auto_stop_in: auto_stop_in
      }
    end

    context 'when auto_stop_in is correct format' do
      let(:auto_stop_in) { '2 days' }

      it 'becomes valid' do
        expect(entry).to be_valid
        expect(entry.auto_stop_in).to eq(auto_stop_in)
      end
    end

    context 'when variables are used for auto_stop_in' do
      let(:auto_stop_in) { '$TTL' }

      it 'becomes valid' do
        expect(entry).to be_valid
        expect(entry.auto_stop_in).to eq(auto_stop_in)
      end
    end
  end

  context 'when configuration is invalid' do
    context 'when configuration is an array' do
      let(:config) { ['env'] }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end

      describe '#errors' do
        it 'contains error about invalid type' do
          expect(entry.errors)
            .to include 'environment config should be a hash or a string'
        end
      end
    end

    context 'when environment name is not present' do
      let(:config) { { url: 'https://example.gitlab.com' } }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end

      describe '#errors?' do
        it 'contains error about missing environment name' do
          expect(entry.errors)
            .to include "environment name can't be blank"
        end
      end
    end
  end

  describe 'kubernetes' do
    let(:config) do
      { name: 'production', kubernetes: kubernetes_config }
    end

    context 'is a string' do
      let(:kubernetes_config) { 'production' }

      it { expect(entry).not_to be_valid }
    end

    context 'is a hash' do
      let(:kubernetes_config) { Hash(namespace: 'production') }

      it { expect(entry).to be_valid }
    end

    context 'is nil' do
      let(:kubernetes_config) { nil }

      it { expect(entry).to be_valid }
    end
  end

  describe 'deployment_tier' do
    let(:config) do
      { name: 'customer-portal', deployment_tier: deployment_tier }
    end

    context 'is a string' do
      let(:deployment_tier) { 'production' }

      it { expect(entry).to be_valid }
    end

    context 'is a hash' do
      let(:deployment_tier) { Hash(tier: 'production') }

      it { expect(entry).not_to be_valid }
    end

    context 'is nil' do
      let(:deployment_tier) { nil }

      it { expect(entry).to be_valid }
    end

    context 'is unknown value' do
      let(:deployment_tier) { 'unknown' }

      it 'is invalid and adds an error' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include("environment deployment tier must be one of #{::Environment.tiers.keys.join(', ')}")
      end
    end
  end
end
