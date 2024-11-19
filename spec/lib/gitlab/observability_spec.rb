# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :observability do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.observability_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_url }

    before do
      stub_rails_env('production')
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when in dev environment' do
      before do
        stub_rails_env('development')
      end

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when in test environment' do
      before do
        stub_rails_env('test')
      end

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_QUERY_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end

  describe '.observability_ingest_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_ingest_url }

    before do
      stub_rails_env('production')
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when in dev environment' do
      before do
        stub_rails_env('development')
      end

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when in test environment' do
      before do
        stub_rails_env('test')
      end

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_INGEST_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end

  describe '.should_enable_observability_auth_scopes?' do
    subject { described_class.should_enable_observability_auth_scopes?(resource) }

    let(:parent) { build_stubbed(:group) }
    let(:resource) do
      build_stubbed(:group, parent: parent).tap do |g|
        g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
      end
    end

    context "when feature flag is enabled" do
      before do
        stub_feature_flags(observability_features: true)
      end

      describe 'when resource is group' do
        it { is_expected.to be true }
      end

      describe 'when resource is project' do
        let(:resource) { build_stubbed(:project, namespace: parent) }

        it { is_expected.to be true }
      end

      describe 'when resource is not a group or project' do
        let(:resource) { build_stubbed(:user) }

        it { is_expected.to be false }
      end
    end

    context "when feature flag is disabled" do
      before do
        stub_feature_flags(observability_features: false)
      end

      describe 'when resource is group' do
        it { is_expected.to be false }
      end

      describe 'when resource is project' do
        let(:resource) { build_stubbed(:project, namespace: parent) }

        it { is_expected.to be false }
      end

      describe 'when resource is not a group or project' do
        let(:resource) { build_stubbed(:user) }

        it { is_expected.to be false }
      end
    end
  end
end
