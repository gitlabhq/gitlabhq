# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddUniqueConstraintToApprovalsUserIdAndMergeRequestId do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:approvals) { table(:approvals) }

  describe '#up' do
    before do
      namespaces.create!(id: 1, name: 'ns', path: 'ns')
      projects.create!(id: 1, namespace_id: 1)
      merge_requests.create!(id: 1, target_branch: 'master', source_branch: 'feature-1', target_project_id: 1)
      merge_requests.create!(id: 2, target_branch: 'master', source_branch: 'feature-2', target_project_id: 1)
    end

    it 'deletes duplicate records and keeps the first one' do
      first_approval = approvals.create!(id: 1, merge_request_id: 1, user_id: 1)
      approvals.create!(id: 2, merge_request_id: 1, user_id: 1)

      migration.up

      expect(approvals.all.to_a).to contain_exactly(first_approval)
    end

    it 'does not delete unique records' do
      unique_approvals = [
        approvals.create(id: 1, merge_request_id: 1, user_id: 1),
        approvals.create(id: 2, merge_request_id: 1, user_id: 2),
        approvals.create(id: 3, merge_request_id: 2, user_id: 1)
      ]

      migration.up

      expect(approvals.all.to_a).to contain_exactly(*unique_approvals)
    end

    it 'creates unique index' do
      migration.up

      expect(migration.index_exists?(:approvals, [:user_id, :merge_request_id], unique: true)).to be_truthy
    end
  end

  describe '#down' do
    it 'removes unique index' do
      migration.up
      migration.down

      expect(migration.index_exists?(:approvals, [:user_id, :merge_request_id], unique: true)).to be_falsey
    end
  end
end
