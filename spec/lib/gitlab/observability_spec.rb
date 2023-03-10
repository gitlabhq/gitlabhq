# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :error_tracking do
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

  describe '.valid_observability_url?' do
    it 'returns true if url is a valid observability url' do
      expect(described_class.valid_observability_url?('https://observe.gitlab.com')).to eq(true)
      expect(described_class.valid_observability_url?('https://observe.gitlab.com:443')).to eq(true)
      expect(described_class.valid_observability_url?('https://observe.gitlab.com/foo/bar')).to eq(true)
      expect(described_class.valid_observability_url?('https://observe.gitlab.com/123/456')).to eq(true)
    end

    it 'returns false if url is a not valid observability url' do
      expect(described_class.valid_observability_url?('http://observe.gitlab.com')).to eq(false)
      expect(described_class.valid_observability_url?('https://observe.gitlab.com:81')).to eq(false)
      expect(described_class.valid_observability_url?('https://foo.observe.gitlab.com')).to eq(false)
      expect(described_class.valid_observability_url?('https://www.gitlab.com')).to eq(false)
      expect(described_class.valid_observability_url?('foo@@@@bar/1/')).to eq(false)
      expect(described_class.valid_observability_url?('foo bar')).to eq(false)
    end
  end

  describe '.allowed_for_action?' do
    let(:group) { build_stubbed(:group) }
    let(:user) { build_stubbed(:user) }

    before do
      allow(described_class).to receive(:allowed?).and_call_original
    end

    it 'returns false if action is nil' do
      expect(described_class.allowed_for_action?(user, group, nil)).to eq(false)
    end

    describe 'allowed? calls' do
      using RSpec::Parameterized::TableSyntax

      where(:action, :permission) do
        :foo          | :admin_observability
        :explore      | :read_observability
        :datasources  | :admin_observability
        :manage       | :admin_observability
        :dashboards   | :read_observability
      end

      with_them do
        it "calls allowed? with #{params[:permission]} when actions is #{params[:action]}" do
          described_class.allowed_for_action?(user, group, action)
          expect(described_class).to have_received(:allowed?).with(user, group, permission)
        end
      end
    end
  end

  describe '.allowed?' do
    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:test_permission) { :read_observability }

    before do
      allow(Ability).to receive(:allowed?).and_return(false)
    end

    subject do
      described_class.allowed?(user, group, test_permission)
    end

    it 'checks if ability is allowed for the given user and group' do
      allow(Ability).to receive(:allowed?).and_return(true)

      subject

      expect(Ability).to have_received(:allowed?).with(user, test_permission, group)
    end

    it 'checks for admin_observability if permission is missing' do
      described_class.allowed?(user, group)

      expect(Ability).to have_received(:allowed?).with(user, :admin_observability, group)
    end

    it 'returns true if the ability is allowed' do
      allow(Ability).to receive(:allowed?).and_return(true)

      expect(subject).to eq(true)
    end

    it 'returns false if the ability is not allowed' do
      allow(Ability).to receive(:allowed?).and_return(false)

      expect(subject).to eq(false)
    end

    it 'returns false if observability url is missing' do
      allow(described_class).to receive(:observability_url).and_return("")

      expect(subject).to eq(false)
    end

    it 'returns false if group is missing' do
      expect(described_class.allowed?(user, nil, :read_observability)).to eq(false)
    end

    it 'returns false if user is missing' do
      expect(described_class.allowed?(nil, group, :read_observability)).to eq(false)
    end
  end
end
