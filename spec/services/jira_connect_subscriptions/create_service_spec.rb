# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscriptions::CreateService do
  let(:installation) { create(:jira_connect_installation) }
  let(:current_user) { create(:user) }
  let(:group) { create(:group) }
  let(:path) { group.full_path }

  subject { described_class.new(installation, current_user, namespace_path: path).execute }

  before do
    group.add_maintainer(current_user)
  end

  shared_examples 'a failed execution' do
    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns an error status' do
      expect(subject[:status]).to eq(:error)
    end
  end

  context 'when user does have access' do
    it 'creates a subscription' do
      expect { subject }.to change { installation.subscriptions.count }.from(0).to(1)
    end

    it 'returns success' do
      expect(subject[:status]).to eq(:success)
    end
  end

  context 'when path is invalid' do
    let(:path) { 'some_invalid_namespace_path' }

    it_behaves_like 'a failed execution'
  end

  context 'when user does not have access' do
    subject { described_class.new(installation, create(:user), namespace_path: path).execute }

    it_behaves_like 'a failed execution'
  end
end
