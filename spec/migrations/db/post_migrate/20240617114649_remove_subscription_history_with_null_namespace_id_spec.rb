# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveSubscriptionHistoryWithNullNamespaceId, feature_category: :subscription_management do
  let(:gitlab_subscription_histories) { table(:gitlab_subscription_histories) }
  let(:group) { table(:namespaces).create!(name: 'top-level-namespace', path: 'top-level-namespace', type: 'Group') }
  let(:gitlab_subscription) { table(:gitlab_subscriptions).create!(namespace_id: group.id) }

  describe "#up" do
    before do
      # dropping the constraint so that the spec works in future version where NOT NULL constraints is added
      connection = described_class.new.connection
      connection.execute('ALTER TABLE gitlab_subscription_histories ALTER COLUMN namespace_id DROP NOT NULL')
    end

    it 'removes gitlab_subscription_histories records with null namespace_id' do
      # create a valid record with correct attributes
      gitlab_subscription_histories.create!(
        gitlab_subscription_id: gitlab_subscription.id, namespace_id: gitlab_subscription.namespace_id
      )
      # create an invalid record to be removed with namespace_id set to nil
      gitlab_subscription_histories.create!(
        gitlab_subscription_id: gitlab_subscription.id,
        namespace_id: nil
      )

      expect(gitlab_subscription_histories.count).to eq(2)

      expect do
        migrate!
      end.to change { gitlab_subscription_histories.where(namespace_id: nil).count }.by(-1)

      expect(gitlab_subscription_histories.where.not(namespace_id: nil).count).to eq(1)
    end
  end
end
