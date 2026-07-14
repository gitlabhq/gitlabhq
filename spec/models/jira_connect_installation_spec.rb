# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallation, feature_category: :integrations do
  describe 'associations' do
    it { is_expected.to have_many(:subscriptions).class_name('JiraConnectSubscription') }
  end

  describe 'validations' do
    subject(:installation) { build(:jira_connect_installation) }

    it { is_expected.to validate_presence_of(:client_key) }
    it { is_expected.to validate_uniqueness_of(:client_key).scoped_to(:organization_id) }
    it { is_expected.to validate_presence_of(:shared_secret) }
    it { is_expected.to validate_presence_of(:base_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:base_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:base_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:display_url) }
    it { is_expected.to allow_value(nil).for(:display_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:display_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:instance_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:instance_url) }
    it { is_expected.not_to allow_value("https://example.coצ").for(:instance_url) }
    it { is_expected.not_to allow_value('https://user:p@ss@example.com').for(:instance_url) }

    it { is_expected.to validate_length_of(:cloud_id).is_at_most(255) }
  end

  describe '#normalize_instance_url' do
    using RSpec::Parameterized::TableSyntax

    subject(:installation) { build(:jira_connect_installation, instance_url: raw_url) }

    where(:case_name, :raw_url, :expected_url) do
      'no scheme'                       | 'gitlab.example.com'           | 'https://gitlab.example.com'
      'no scheme with subpath'          | 'gitlab.example.com/gitlab'    | 'https://gitlab.example.com/gitlab'
      'leading and trailing whitespace' | '  gitlab.example.com  '       | 'https://gitlab.example.com'
      'https:// scheme already'         | 'https://gitlab.example.com'   | 'https://gitlab.example.com'
      'http:// scheme already'          | 'http://gitlab.example.com'    | 'http://gitlab.example.com'
      'non-http scheme'                 | 'ftp://gitlab.example.com'     | 'ftp://gitlab.example.com'
      'no dot (not host-like)'          | 'not-a-url'                    | 'not-a-url'
      'path-only value'                 | '/gitlab'                      | '/gitlab'
      'blank string'                    | ''                             | ''
      'nil'                             | nil                            | nil
    end

    with_them do
      it 'normalizes the value as expected' do
        installation.valid?

        expect(installation.instance_url).to eq(expected_url)
      end
    end
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
      allow(Gitlab.config.gitlab).to receive(:url).and_return('http://test.host')
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

  describe '#forge_direct?' do
    let(:installation) { build(:jira_connect_installation) }

    subject(:result) { installation.forge_direct? }

    it { expect(result).to eq(false) }

    context 'when both the apiBaseUrl and system token are present' do
      let(:installation) do
        build(:jira_connect_installation,
          jira_api_base_url: 'https://api.atlassian.com/ex/jira/cloud-xyz',
          forge_system_token: 'sys-token')
      end

      it { expect(result).to eq(true) }
    end

    context 'when only the apiBaseUrl is present' do
      let(:installation) do
        build(:jira_connect_installation, jira_api_base_url: 'https://api.atlassian.com/ex/jira/cloud-xyz')
      end

      it { expect(result).to eq(false) }
    end

    context 'when only the system token is present' do
      let(:installation) { build(:jira_connect_installation, forge_system_token: 'sys-token') }

      it { expect(result).to eq(false) }
    end
  end

  describe 'jira_api_base_url validation' do
    subject(:installation) { build(:jira_connect_installation) }

    it { is_expected.to allow_value(nil).for(:jira_api_base_url) }
    it { is_expected.to allow_value('https://api.atlassian.com/ex/jira/cloud-xyz').for(:jira_api_base_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:jira_api_base_url) }
  end
end
