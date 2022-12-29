# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability do
  describe '.observability_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_url }

    before do
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end

  describe '.observability_enabled?' do
    let_it_be(:group) { build(:user) }
    let_it_be(:user) { build(:group) }

    subject do
      described_class.observability_enabled?(user, group)
    end

    it 'checks if read_observability ability is allowed for the given user and group' do
      allow(Ability).to receive(:allowed?).and_return(true)

      subject

      expect(Ability).to have_received(:allowed?).with(user, :read_observability, group)
    end

    it 'returns true if the read_observability ability is allowed' do
      allow(Ability).to receive(:allowed?).and_return(true)

      expect(subject).to eq(true)
    end

    it 'returns false if the read_observability ability is not allowed' do
      allow(Ability).to receive(:allowed?).and_return(false)

      expect(subject).to eq(false)
    end

    it 'returns false if observability url is missing' do
      allow(described_class).to receive(:observability_url).and_return("")

      expect(subject).to eq(false)
    end
  end
end
