# frozen_string_literal: true

require 'spec_helper'
require_migration! 'clean_up_fix_merge_request_diff_commit_users'

RSpec.describe CleanUpFixMergeRequestDiffCommitUsers, :migration, feature_category: :code_review_workflow do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_namespace) { namespaces.create!(name: 'project2', path: 'project2', type: 'Project') }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }

  describe '#up' do
    it 'finalizes the background migration' do
      expect(described_class).to be_finalize_background_migration_of('FixMergeRequestDiffCommitUsers')

      migrate!
    end
  end
end
