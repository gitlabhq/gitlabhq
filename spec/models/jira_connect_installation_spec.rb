# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectInstallation do
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
  end

  describe '.for_project' do
    let(:other_group) { create(:group) }
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:project) { create(:project, group: group) }

    subject { described_class.for_project(project) }

    it 'returns installations with subscriptions for project' do
      sub_on_project_namespace = create(:jira_connect_subscription, namespace: group)
      sub_on_ancestor_namespace = create(:jira_connect_subscription, namespace: parent_group)

      # Subscription on other group that shouldn't be returned
      create(:jira_connect_subscription, namespace: other_group)

      expect(subject).to contain_exactly(sub_on_project_namespace.installation, sub_on_ancestor_namespace.installation)
    end

    it 'returns distinct installations' do
      subscription = create(:jira_connect_subscription, namespace: group)
      create(:jira_connect_subscription, namespace: parent_group, installation: subscription.installation)

      expect(subject).to contain_exactly(subscription.installation)
    end
  end
end
