# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::MergeRequestsPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity) do
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

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:importer_user_mapping_enabled) { false }

  let(:mr) do
    {
      'iid' => 7,
      'author_id' => 22,
      'source_project_id' => 1234,
      'target_project_id' => 1234,
      'title' => 'Imported MR',
      'description' => 'Description',
      'state' => 'opened',
      'source_branch' => 'feature',
      'target_branch' => 'main',
      'source_branch_sha' => 'ABCD',
      'target_branch_sha' => 'DCBA',
      'created_at' => '2020-06-14T15:02:47.967Z',
      'updated_at' => '2020-06-14T15:03:47.967Z',
      'merge_request_diff' => {
        'state' => 'collected',
        'base_commit_sha' => 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f',
        'head_commit_sha' => 'a97f74ddaa848b707bea65441c903ae4bf5d844d',
        'start_commit_sha' => '9eea46b5c72ead701c22f516474b95049c9d9462',
        'diff_type' => 1,
        'merge_request_diff_commits' => [
          {
            'sha' => 'COMMIT1',
            'relative_order' => 0,
            'message' => 'commit message',
            'authored_date' => '2014-08-06T08:35:52.000+02:00',
            'committed_date' => '2014-08-06T08:35:52.000+02:00',
            'commit_author' => {
              'name' => 'Commit Author',
              'email' => 'gitlab@example.com'
            },
            'committer' => {
              'name' => 'Committer',
              'email' => 'committer@example.com'
            }
          }
        ],
        'merge_request_diff_files' => [
          {
            'relative_order' => 0,
            'utf8_diff' => '--- a/.gitignore\n+++ b/.gitignore\n@@ -1 +1 @@ test\n',
            'new_path' => '.gitignore',
            'old_path' => '.gitignore',
            'a_mode' => '100644',
            'b_mode' => '100644',
            'new_file' => false,
            'renamed_file' => false,
            'deleted_file' => false,
            'too_large' => false
          }
        ]
      }
    }.merge(attributes)
  end

  let(:attributes) { {} }
  let(:imported_mr) { project.merge_requests.find_by_title(mr['title']) }

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)
      group.add_maintainer(another_user)

      ::BulkImports::UsersMapper.new(context: context).cache_source_user_id(42, another_user.id)

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:remove_tmp_dir)
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[mr, 0]]))
      end

      allow(project.repository).to receive(:fetch_source_branch!).and_return(true)
      allow(project.repository).to receive(:branch_exists?).and_return(false)
      allow(project.repository).to receive(:create_branch)

      allow(::Projects::ImportExport::AfterImportMergeRequestsWorker).to receive(:perform_async)
      allow(pipeline).to receive(:set_source_objects_counter)

      allow(context).to receive(:importer_user_mapping_enabled?).and_return(importer_user_mapping_enabled)
      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original
    end

    it 'imports a merge request' do
      pipeline.run

      expect(project.merge_requests.count).to eq(1)
      expect(imported_mr.title).to eq(mr['title'])
      expect(imported_mr.description).to eq(mr['description'])
      expect(imported_mr.state).to eq(mr['state'])
      expect(imported_mr.iid).to eq(mr['iid'])
      expect(imported_mr.created_at).to eq(mr['created_at'])
      expect(imported_mr.updated_at).to eq(mr['updated_at'])
      expect(imported_mr.author).to eq(user)
    end

    context 'when a merge_request with the same IID exists' do
      let!(:existing_mr) do
        create(:merge_request, target_project: project, source_project: project, iid: mr['iid'],
          description: 'old description')
      end

      it 'deletes the existing record and imports the new record' do
        expect { pipeline.run }.to change { MergeRequest.exists?(existing_mr.id) }.from(true).to(false)

        expect(project.merge_requests.count).to eq(1)
        expect(imported_mr.iid).to eq(mr['iid'])
        expect(imported_mr.description).to eq(mr['description'])
      end
    end

    context 'merge request state' do
      context 'when mr is closed' do
        let(:attributes) { { 'state' => 'closed' } }

        it 'imported mr as closed' do
          pipeline.run

          expect(imported_mr.state).to eq(attributes['state'])
        end
      end

      context 'when mr is merged' do
        let(:attributes) { { 'state' => 'merged' } }

        it 'imported mr as merged' do
          pipeline.run

          expect(imported_mr.state).to eq(attributes['state'])
        end
      end
    end

    context 'source & target project' do
      it 'has the new project as target' do
        pipeline.run

        expect(imported_mr.target_project).to eq(project)
      end

      it 'has the new project as source' do
        pipeline.run

        expect(imported_mr.source_project).to eq(project)
      end

      context 'when source/target projects differ' do
        let(:attributes) { { 'source_project_id' => 4321 } }

        it 'has no source' do
          pipeline.run

          expect(imported_mr.source_project).to be_nil
        end

        context 'when diff_head_sha is present' do
          let(:attributes) { { 'diff_head_sha' => 'HEAD', 'source_project_id' => 4321 } }

          it 'has the new project as source' do
            pipeline.run

            expect(imported_mr.source_project).to eq(project)
          end
        end
      end
    end

    context 'resource label events' do
      let(:attributes) { { 'resource_label_events' => [{ 'action' => 'add', 'user_id' => 1 }] } }

      it 'restores resource label events' do
        pipeline.run

        expect(imported_mr.resource_label_events.first.action).to eq('add')
      end
    end

    context 'award emoji' do
      let(:attributes) { { 'award_emoji' => [{ 'name' => 'tada', 'user_id' => 22 }] } }

      it 'has award emoji' do
        pipeline.run

        expect(imported_mr.award_emoji.first.name).to eq(attributes['award_emoji'].first['name'])
      end
    end

    context 'notes' do
      let(:note) { imported_mr.notes.first }
      let(:attributes) do
        {
          'notes' => [
            {
              'note' => 'Issue note',
              'note_html' => '<p>something else entirely</p>',
              'cached_markdown_version' => 917504,
              'author_id' => 22,
              'author' => { 'name' => 'User 22' },
              'created_at' => '2016-06-14T15:02:56.632Z',
              'updated_at' => '2016-06-14T15:02:47.770Z',
              'award_emoji' => [{ 'name' => 'clapper', 'user_id' => 22 }]
            }
          ]
        }
      end

      it 'imports mr note' do
        pipeline.run

        expect(note).to be_present
        expect(note.note).to include('By User 22')
        expect(note.note).to include(attributes['notes'].first['note'])
        expect(note.author).to eq(user)
      end

      it 'has award emoji' do
        pipeline.run

        emoji = note.award_emoji.first

        expect(emoji.name).to eq('clapper')
        expect(emoji.user).to eq(user)
      end

      it 'does not import note_html' do
        pipeline.run

        expect(note.note_html).to match(attributes['notes'].first['note'])
        expect(note.note_html).not_to match(attributes['notes'].first['note_html'])
      end
    end

    context 'system note metadata' do
      let(:attributes) do
        {
          'notes' => [
            {
              'note' => 'added 3 commits',
              'system' => true,
              'author_id' => 22,
              'author' => { 'name' => 'User 22' },
              'created_at' => '2016-06-14T15:02:56.632Z',
              'updated_at' => '2016-06-14T15:02:47.770Z',
              'system_note_metadata' => { 'action' => 'commit', 'commit_count' => 3 }
            }
          ]
        }
      end

      it 'restores system note metadata' do
        pipeline.run

        note = imported_mr.notes.first

        expect(note.system).to eq(true)
        expect(note.noteable_type).to eq('MergeRequest')
        expect(note.system_note_metadata.action).to eq('commit')
        expect(note.system_note_metadata.commit_count).to eq(3)
      end
    end

    context 'diffs' do
      it 'imports merge request diff' do
        pipeline.run

        expect(imported_mr.merge_request_diff).to be_present
      end

      it 'enqueues AfterImportMergeRequestsWorker worker' do
        pipeline.run

        expect(::Projects::ImportExport::AfterImportMergeRequestsWorker)
          .to have_received(:perform_async)
          .with(project.id)
      end

      it 'imports diff files' do
        pipeline.run

        expect(imported_mr.merge_request_diff.merge_request_diff_files.count).to eq(1)
      end

      context 'diff commits' do
        it 'imports diff commits' do
          pipeline.run

          expect(imported_mr.merge_request_diff.merge_request_diff_commits.count).to eq(1)
        end

        it 'assigns committer and author details to diff commits' do
          pipeline.run

          commit = imported_mr.merge_request_diff.merge_request_diff_commits.first

          expect(commit.commit_author_id).not_to be_nil
          expect(commit.committer_id).not_to be_nil
        end

        it 'assigns the correct commit users to diff commits' do
          pipeline.run

          commit = MergeRequestDiffCommit.find_by(sha: 'COMMIT1')

          expect(commit.commit_author.name).to eq('Commit Author')
          expect(commit.commit_author.email).to eq('gitlab@example.com')
          expect(commit.committer.name).to eq('Committer')
          expect(commit.committer.email).to eq('committer@example.com')
        end
      end
    end

    context 'labels' do
      let(:attributes) do
        {
          'label_links' => [
            { 'label' => { 'title' => 'imported label 1', 'type' => 'ProjectLabel' } },
            { 'label' => { 'title' => 'imported label 2', 'type' => 'ProjectLabel' } }
          ]
        }
      end

      it 'imports labels' do
        pipeline.run

        expect(imported_mr.labels.pluck(:title)).to contain_exactly('imported label 1', 'imported label 2')
      end
    end

    context 'milestone' do
      let(:attributes) { { 'milestone' => { 'title' => 'imported milestone' } } }

      it 'imports milestone' do
        pipeline.run

        expect(imported_mr.milestone.title).to eq(attributes.dig('milestone', 'title'))
      end
    end

    context 'user assignments' do
      let(:attributes) do
        {
          key => [
            {
              'user_id' => 22,
              'created_at' => '2020-01-07T11:21:21.235Z'
            },
            {
              'user_id' => 42,
              'created_at' => '2020-01-08T12:21:21.235Z'
            }
          ]
        }
      end

      context 'assignees' do
        let(:key) { 'merge_request_assignees' }

        it 'imports mr assignees' do
          pipeline.run

          assignees = imported_mr.merge_request_assignees

          expect(assignees.pluck(:user_id)).to contain_exactly(user.id, another_user.id)
        end
      end

      context 'approvals' do
        let(:key) { 'approvals' }

        it 'imports mr approvals' do
          pipeline.run

          approvals = imported_mr.approvals

          expect(approvals.pluck(:user_id)).to contain_exactly(user.id, another_user.id)
        end
      end

      context 'reviewers' do
        let(:key) { 'merge_request_reviewers' }

        it 'imports mr reviewers' do
          pipeline.run

          reviewers = imported_mr.merge_request_reviewers

          expect(reviewers.pluck(:user_id)).to contain_exactly(user.id, another_user.id)
        end
      end
    end

    context 'when importer_user_mapping is enabled' do
      let_it_be(:source_user) do
        create(:import_source_user,
          import_type: ::Import::SOURCE_DIRECT_TRANSFER,
          namespace: group,
          source_user_identifier: 101,
          source_hostname: bulk_import.configuration.url
        )
      end

      let(:importer_user_mapping_enabled) { true }

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

        expect(merge_request.author).to be_placeholder
        expect(merge_request.merge_user).to be_placeholder
        expect(merge_request.last_edited_by).to be_placeholder
        expect(merge_request.updated_by).to be_placeholder
        expect(approval.user).to be_placeholder
        expect(metrics.merged_by).to be_placeholder
        expect(metrics.latest_closed_by).to be_placeholder
        expect(merge_request_assignee.assignee).to be_placeholder
        expect(merge_request_reviewer.reviewer).to be_placeholder
        expect(event.author).to be_placeholder
        expect(timelog.user).to be_placeholder
        expect(note.author).to be_placeholder
        expect(note.updated_by).to be_placeholder
        expect(note.resolved_by).to be_placeholder
        expect(resource_label_event.user).to be_placeholder
        expect(resource_milestone_event.user).to be_placeholder
        expect(resource_state_events.user).to be_placeholder
        expect(award_emoji.user).to be_placeholder

        source_user = Import::SourceUser.find_by(source_user_identifier: 101)
        expect(source_user.placeholder_user).to be_placeholder
        expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(18).times
      end
    end
  end
end
