# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::MergeEvent, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }
  let_it_be(:merge_event) do
    {
      id: 3,
      committer_user: 'John Merges',
      committer_username: 'pull_request_author',
      committer_email: 'pull_request_author@example.org',
      merge_timestamp: now,
      merge_commit: '12345678'
    }
  end

  let_it_be(:source_user) { generate_source_user(project, merge_event[:committer_username]) }

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'pushes placeholder references' do
      importer.execute(merge_event)

      cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
      expect(cached_references).to contain_exactly(
        ['MergeRequest::Metrics', instance_of(Integer), 'merged_by_id', source_user.id]
      )
    end

    it 'imports the merge event' do
      importer.execute(merge_event)

      metrics = merge_request.metrics.reload

      expect(metrics.merged_by_id).to eq(source_user.mapped_user_id)
      expect(metrics.merged_at).to eq(merge_event[:merge_timestamp])
      expect(merge_request.merge_commit_sha).to eq(merge_event[:merge_commit])
    end

    it 'logs its progress' do
      expect_log(stage: 'import_merge_event', message: 'starting', iid: merge_request.iid, event_id: 3)
      expect_log(stage: 'import_merge_event', message: 'finished', iid: merge_request.iid, event_id: 3)

      importer.execute(merge_event)
    end

    context 'when user contribution mapping is disabled' do
      let_it_be(:pull_request_author) do
        create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org')
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'imports the merge event' do
        importer.execute(merge_event)

        metrics = merge_request.metrics.reload
        expect(metrics.merged_by_id).to eq(pull_request_author.id)
      end

      it 'does not push placeholder references' do
        importer.execute(merge_event)

        cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
        expect(cached_references).to be_empty
      end
    end
  end
end
