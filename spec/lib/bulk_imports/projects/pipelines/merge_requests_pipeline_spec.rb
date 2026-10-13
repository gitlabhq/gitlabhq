# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::MergeRequestsPipeline, feature_category: :importers do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:group, freeze: false) { create(:group, owners: user) }
  let_it_be(:project, freeze: false) { create(:project, :repository, group: group) }
  let_it_be(:bulk_import, freeze: false) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity, freeze: false) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker, freeze: false) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context, freeze: false) { BulkImports::Pipeline::Context.new(tracker) }

  let_it_be(:source_user, freeze: false) do
    create(:import_source_user,
      import_type: ::Import::SOURCE_DIRECT_TRANSFER,
      namespace: group,
      source_user_identifier: 101,
      source_hostname: bulk_import.configuration.url,
      placeholder_user: create(:user, :import_user)
    )
  end

  let(:minimal_mr) do
    {
      title: 'Imported MR',
      author_id: 101,
      iid: 38,
      source_project_id: 1234,
      target_project_id: 1234,
      description: 'Description',
      source_branch: 'feature',
      target_branch: 'main',
      source_branch_sha: 'ABCD',
      target_branch_sha: 'DCBA',
      state: 'opened'
    }
  end

  let(:mr) do
    {
      title: 'Imported MR',
      author_id: 101,
      iid: 38,
      source_project_id: 1234,
      target_project_id: 1234,
      description: 'Description',
      source_branch: 'feature',
      target_branch: 'main',
      source_branch_sha: 'ABCD',
      target_branch_sha: 'DCBA',
      updated_by_id: 101,
      merge_user_id: 101,
      last_edited_at: '2019-12-27T00:00:00.000Z',
      last_edited_by_id: 101,
      state: 'opened',
      metrics: { merged_by_id: 101, latest_closed_by_id: 101 },
      approvals: [{ user_id: 101 }],
      merge_request_assignees: [{ user_id: 101 }],
      merge_request_reviewers: [{ user_id: 101, state: 'unreviewed' }],
      events: [{ author_id: 101, action: 'created', target_type: 'MergeRequest' }],
      timelogs: [{ time_spent: 72000, spent_at: '2019-12-27T00:00:00.000Z', user_id: 101 }],
      notes: [{ note: 'Note', noteable_type: 'Issue', author_id: 101, updated_by_id: 101, resolved_by_id: 101 }],
      resource_label_events: [{ action: 'add', user_id: 101, label: { title: 'Ambalt', color: '#33594f' } }],
      resource_milestone_events: [{ user_id: 101, action: 'add', state: 'opened', milestone: { title: 'Sprint' } }],
      resource_state_events: [{ user_id: 101, state: 'closed' }],
      award_emoji: [{ name: 'clapper', user_id: 101 }]
    }.deep_stringify_keys
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:remove_tmp_dir)
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[mr, 0]]))
      end

      allow(project.repository).to receive_messages(fetch_source_branch!: true, branch_exists?: false)
      allow(project.repository).to receive(:create_branch)

      allow(::Projects::ImportExport::AfterImportMergeRequestsWorker).to receive(:perform_async)
      allow(pipeline).to receive(:set_source_objects_counter)

      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original
    end

    it 'imports merge_requests and maps user references to placeholder users', :aggregate_failures do
      pipeline.run

      merge_request = project.merge_requests.last
      approval = merge_request.approvals.first
      metrics = merge_request.metrics
      merge_request_assignee = merge_request.merge_request_assignees.first
      merge_request_reviewer = merge_request.merge_request_reviewers.first
      event = merge_request.events.first
      note = merge_request.notes.first
      timelog = merge_request.timelogs.first
      resource_label_event = merge_request.resource_label_events.first
      resource_milestone_event = merge_request.resource_milestone_events.first
      resource_state_events = merge_request.resource_state_events.first
      award_emoji = merge_request.award_emoji.first

      expect(merge_request.author).to be_import_user
      expect(merge_request.merge_user).to be_import_user
      expect(merge_request.last_edited_by).to be_import_user
      expect(merge_request.updated_by).to be_import_user
      expect(approval.user).to be_import_user
      expect(metrics.merged_by).to be_import_user
      expect(metrics.latest_closed_by).to be_import_user
      expect(merge_request_assignee.assignee).to be_import_user
      expect(merge_request_reviewer.reviewer).to be_import_user
      expect(event.author).to be_import_user
      expect(timelog.user).to be_import_user
      expect(note.author).to be_import_user
      expect(note.updated_by).to be_import_user
      expect(note.resolved_by).to be_import_user
      expect(resource_label_event.user).to be_import_user
      expect(resource_milestone_event.user).to be_import_user
      expect(resource_state_events.user).to be_import_user
      expect(award_emoji.user).to be_import_user

      source_user = Import::SourceUser.find_by(source_user_identifier: 101)
      expect(source_user.placeholder_user).to be_import_user
      expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(18).times
    end

    context 'when a merge_request with the same IID exists' do
      let!(:existing_mr) do
        create(:merge_request, target_project: project, source_project: project, iid: mr['iid'],
          description: 'old description')
      end

      it 'deletes the existing record and imports the new record' do
        expect { pipeline.run }.to change { MergeRequest.exists?(existing_mr.id) }.from(true).to(false)

        imported_mr = project.merge_requests.find_by_iid(mr['iid'])

        expect(project.merge_requests.count).to eq(1)
        expect(imported_mr.description).to eq(mr['description'])
      end
    end

    context 'merge request state' do
      context 'when mr is closed' do
        let(:mr) { minimal_mr.merge(state: 'closed').deep_stringify_keys }

        it 'imports mr as closed' do
          pipeline.run

          expect(project.merge_requests.last.state).to eq('closed')
        end
      end

      context 'when mr is merged' do
        let(:mr) { minimal_mr.merge(state: 'merged').deep_stringify_keys }

        it 'imports mr as merged' do
          pipeline.run

          expect(project.merge_requests.last.state).to eq('merged')
        end
      end
    end

    context 'diffs' do
      let(:mr) do
        minimal_mr.merge(
          merge_request_diff: {
            state: 'collected',
            base_commit_sha: 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f',
            head_commit_sha: 'a97f74ddaa848b707bea65441c903ae4bf5d844d',
            start_commit_sha: '9eea46b5c72ead701c22f516474b95049c9d9462',
            diff_type: 1,
            merge_request_diff_commits: [
              {
                sha: 'COMMIT1',
                relative_order: 0,
                message: 'commit message',
                authored_date: '2014-08-06T08:35:52.000+02:00',
                committed_date: '2014-08-06T08:35:52.000+02:00',
                commit_author: {
                  name: 'Commit Author',
                  email: 'gitlab@example.com'
                },
                committer: {
                  name: 'Committer',
                  email: 'committer@example.com'
                }
              }
            ],
            merge_request_diff_files: [
              {
                relative_order: 0,
                utf8_diff: "--- a/.gitignore\n+++ b/.gitignore\n@@ -1 +1 @@ test\n",
                new_path: '.gitignore',
                old_path: '.gitignore',
                a_mode: '100644',
                b_mode: '100644',
                new_file: false,
                renamed_file: false,
                deleted_file: false,
                too_large: false
              }
            ]
          }
        ).deep_stringify_keys
      end

      it 'imports merge request diff' do
        pipeline.run

        expect(project.merge_requests.last.merge_request_diff).to be_present
      end

      it 'enqueues AfterImportMergeRequestsWorker worker' do
        pipeline.run

        expect(::Projects::ImportExport::AfterImportMergeRequestsWorker)
          .to have_received(:perform_async)
          .with(project.id)
      end

      it 'imports diff files' do
        pipeline.run

        expect(project.merge_requests.last.merge_request_diff.merge_request_diff_files.count).to eq(1)
      end

      context 'diff commits' do
        it 'imports diff commits' do
          pipeline.run

          expect(project.merge_requests.last.merge_request_diff.merge_request_diff_commits.count).to eq(1)
        end

        it 'assigns the correct commit author and committer details to diff commits', :aggregate_failures do
          pipeline.run

          commit = project.merge_requests.last.merge_request_diff.merge_request_diff_commits.first

          expect(commit.commit_author.name).to eq('Commit Author')
          expect(commit.commit_author.email).to eq('gitlab@example.com')
          expect(commit.committer.name).to eq('Committer')
          expect(commit.committer.email).to eq('committer@example.com')
        end
      end
    end

    context 'labels' do
      let(:mr) do
        minimal_mr.merge(
          label_links: [
            { label: { title: 'imported label 1', type: 'ProjectLabel' } },
            { label: { title: 'imported label 2', type: 'ProjectLabel' } }
          ]
        ).deep_stringify_keys
      end

      it 'imports labels' do
        pipeline.run

        expect(project.merge_requests.last.labels.pluck(:title))
          .to contain_exactly('imported label 1', 'imported label 2')
      end
    end

    context 'milestone' do
      let(:mr) { minimal_mr.merge(milestone: { title: 'imported milestone' }).deep_stringify_keys }

      it 'imports milestone' do
        pipeline.run

        expect(project.merge_requests.last.milestone.title).to eq('imported milestone')
      end
    end

    context 'system note metadata' do
      let(:mr) do
        minimal_mr.merge(
          notes: [
            {
              note: 'added 3 commits',
              system: true,
              author_id: 101,
              noteable_type: 'MergeRequest',
              system_note_metadata: { action: 'commit', commit_count: 3 }
            }
          ]
        ).deep_stringify_keys
      end

      it 'restores system note metadata', :aggregate_failures do
        pipeline.run

        note = project.merge_requests.last.notes.first

        expect(note.system).to be(true)
        expect(note.noteable_type).to eq('MergeRequest')
        expect(note.system_note_metadata.action).to eq('commit')
        expect(note.system_note_metadata.commit_count).to eq(3)
      end
    end

    context 'when direct reassignment is supported' do
      before do
        allow(Import::DirectReassignService).to receive(:supported?).and_return(true)
      end

      it 'does not push any placeholder references' do
        pipeline.run

        expect(Import::PlaceholderReferences::PushService).not_to have_received(:from_record)
      end
    end
  end
end
