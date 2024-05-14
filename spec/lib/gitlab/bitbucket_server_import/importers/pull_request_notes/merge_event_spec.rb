# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::MergeEvent, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :repository, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }

  let_it_be(:pull_request_author) do
    create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org')
  end

  let_it_be(:merge_event) do
    {
      id: 3,
      committer_email: pull_request_author.email,
      merge_timestamp: now,
      merge_commit: '12345678'
    }
  end

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute' do
    it 'imports the merge event' do
      importer.execute(merge_event)

      merge_request.reload

      expect(merge_request.metrics.merged_by).to eq(pull_request_author)
      expect(merge_request.metrics.merged_at).to eq(merge_event[:merge_timestamp])
      expect(merge_request.merge_commit_sha).to eq(merge_event[:merge_commit])
    end

    it 'logs its progress' do
      expect_log(stage: 'import_merge_event', message: 'starting', iid: merge_request.iid, event_id: 3)
      expect_log(stage: 'import_merge_event', message: 'finished', iid: merge_request.iid, event_id: 3)

      importer.execute(merge_event)
    end
  end
end
