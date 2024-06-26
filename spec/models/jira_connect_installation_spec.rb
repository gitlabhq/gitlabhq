# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallation, feature_category: :integrations do
  describe 'associations' do
    it { is_expected.to have_many(:subscriptions).class_name('JiraConnectSubscription') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:client_key) }
    it { is_expected.to validate_uniqueness_of(:client_key) }
    it { is_expected.to validate_presence_of(:shared_secret) }
    it { is_expected.to validate_presence_of(:base_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:base_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:base_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:instance_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:instance_url) }
  end

  describe 'scopes' do
    let_it_be(:jira_connect_subscription) { create(:jira_connect_subscription) }

    describe '.for_project' do
      let_it_be(:other_group) { create(:group) }
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:project) { create(:project, group: group) }

      subject { described_class.for_project(project) }

      it 'returns installations with subscriptions for project' do
        sub_on_project_namespace = create(:jira_connect_subscription, namespace: group)
        sub_on_ancestor_namespace = create(:jira_connect_subscription, namespace: parent_group)

        # Subscription on other group that shouldn't be returned
        create(:jira_connect_subscription, namespace: other_group)

        expect(subject).to contain_exactly(
          sub_on_project_namespace.installation, sub_on_ancestor_namespace.installation
        )
      end

      it 'returns distinct installations' do
        subscription = create(:jira_connect_subscription, namespace: group)
        create(:jira_connect_subscription, namespace: parent_group, installation: subscription.installation)

        expect(subject).to contain_exactly(subscription.installation)
      end
    end

    describe '.direct_installations' do
      subject { described_class.direct_installations }

      it { is_expected.to contain_exactly(jira_connect_subscription.installation) }
    end

    describe '.proxy_installations' do
      subject { described_class.proxy_installations }

      it { is_expected.to be_empty }

      context 'with an installation on a self-managed instance' do
        let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'http://self-managed-gitlab.com') }

        it { is_expected.to contain_exactly(installation) }
      end
    end
  end

  describe '#oauth_authorization_url' do
    let(:installation) { build(:jira_connect_installation) }

    subject { installation.oauth_authorization_url }

    before do
      allow(Gitlab).to receive_message_chain('config.gitlab.url') { 'http://test.host' }
    end

    it { is_expected.to eq('http://test.host') }

    context 'with instance_url' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://gitlab.example.com') }

      it { is_expected.to eq('https://gitlab.example.com') }
    end
  end

  describe 'audience_url' do
    let(:installation) { build(:jira_connect_installation) }

    subject(:audience) { installation.audience_url }

    it { is_expected.to eq(nil) }

    context 'when proxy installation' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://example.com') }

      it { is_expected.to eq('https://example.com/-/jira_connect') }
    end
  end

  describe 'audience_installed_event_url' do
    let(:installation) { build(:jira_connect_installation) }

    subject(:audience) { installation.audience_installed_event_url }

    it { is_expected.to eq(nil) }

    context 'when proxy installation' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://example.com') }

      it { is_expected.to eq('https://example.com/-/jira_connect/events/installed') }
    end
  end

  describe 'audience_uninstalled_event_url' do
    let(:installation) { build(:jira_connect_installation) }

    subject(:audience) { installation.audience_uninstalled_event_url }

    it { is_expected.to eq(nil) }

    context 'when proxy installation' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://example.com') }

      it { is_expected.to eq('https://example.com/-/jira_connect/events/uninstalled') }
    end
  end

  describe 'create_branch_url' do
    context 'when the jira installation is not for a self-managed instance' do
      let(:installation) { build(:jira_connect_installation) }

      subject(:create_branch) { installation.create_branch_url }

      it { is_expected.to eq(nil) }
    end

    context 'when the jira installation is for a self-managed instance' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://example.com') }

      subject(:create_branch) { installation.create_branch_url }

      it { is_expected.to eq('https://example.com/-/jira_connect/branches/new') }
    end
  end

  describe 'proxy?' do
    let(:installation) { build(:jira_connect_installation) }

    subject { installation.proxy? }

    it { is_expected.to eq(false) }

    context 'when instance_url is present' do
      let(:installation) { build(:jira_connect_installation, instance_url: 'https://example.com') }

      it { is_expected.to eq(true) }
    end
  end
end
