# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInvalidMergeRequestContextCommitsRecords, feature_category: :code_review_workflow do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let!(:merge_request) do
    table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'feature')
  end

  let!(:context_commits) { table(:merge_request_context_commits) }
  let!(:args) do
    {
      sha: OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex),
      relative_order: 0
    }
  end

  describe '#up' do
    before do
      context_commits.create!(**args.merge(merge_request_id: merge_request.id, author_name: 'John'))
      context_commits.create!(**args.merge(merge_request_id: nil, author_name: 'Jane'))
      context_commits.create!(**args.merge(merge_request_id: nil, author_name: 'Paul'))

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes records without a merge_request_id' do
      migrate!

      expect(context_commits.count).to eq(1)
      expect(context_commits.first).to have_attributes(
        merge_request_id: merge_request.id,
        author_name: 'John'
      )
    end

    it 'does nothing on gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      migrate!

      expect(context_commits.count).to eq(3)
    end
  end
end
