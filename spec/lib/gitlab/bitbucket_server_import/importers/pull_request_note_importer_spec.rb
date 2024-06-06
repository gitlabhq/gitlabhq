# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNoteImporter, feature_category: :importers do
  include AfterNextHelpers

  let_it_be_with_reload(:project) do
    create(:project, :repository, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let_it_be(:merge_request_iid) { 7 }
  let_it_be(:object) do
    {
      iid: merge_request_iid,
      comment_type: 'merge_event',
      comment_id: 123,
      comment: {}
    }
  end

  def expect_log(stage:, message:, iid:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid))
  end

  subject(:importer) { described_class.new(project.reload, object.to_hash) }

  describe '#execute' do
    shared_examples 'import is skipped' do
      it 'does not log and does not import notes' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .not_to receive(:info).with(include(import_stage: 'import_pull_request_note', message: 'starting'))

        expect { importer.execute }.not_to change { Note.count }
      end
    end

    context 'when a matching merge request is not found' do
      it 'logs its progress' do
        expect_next(Gitlab::BitbucketServerImport::Importers::PullRequestNotes::BaseImporter).not_to receive(:execute)

        expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
        expect_log(stage: 'import_pull_request_note', message: 'skipped', iid: merge_request_iid)
        expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

        importer.execute
      end
    end

    context 'when a matching merge request is found' do
      let_it_be(:merge_request) { create(:merge_request, iid: merge_request_iid, source_project: project) }

      context 'when a matching importer is not found' do
        let_it_be(:object) do
          {
            iid: merge_request_iid,
            comment_type: 'unknown',
            comment_id: 123,
            comment: {}
          }
        end

        it 'logs its progress' do
          expect_next(Gitlab::BitbucketServerImport::Importers::PullRequestNotes::BaseImporter).not_to receive(:execute)

          expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
          allow(Gitlab::BitbucketServerImport::Logger).to receive(:debug).and_call_original
          expect(Gitlab::BitbucketServerImport::Logger)
            .to receive(:debug).with(
              include(message: 'UNSUPPORTED_EVENT_TYPE', comment_type: 'unknown', comment_id: 123)
            )
          expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

          importer.execute
        end
      end

      context 'when a matching importer found' do
        context 'when comment type is merge_event' do
          let_it_be(:object) do
            {
              iid: merge_request_iid,
              comment_type: 'merge_event',
              comment_id: 123,
              comment: {}
            }
          end

          it 'imports the merge_event' do
            expect_next(
              Gitlab::BitbucketServerImport::Importers::PullRequestNotes::MergeEvent,
              project,
              merge_request
            ).to receive(:execute).with(object[:comment])

            expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
            expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

            importer.execute
          end
        end

        context 'when comment type is approved_event' do
          let_it_be(:object) do
            {
              iid: merge_request_iid,
              comment_type: 'approved_event',
              comment_id: 123,
              comment: {}
            }
          end

          it 'imports the approved_event' do
            expect_next(
              Gitlab::BitbucketServerImport::Importers::PullRequestNotes::ApprovedEvent,
              project,
              merge_request
            ).to receive(:execute).with(object[:comment])

            expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
            expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

            importer.execute
          end
        end

        context 'when comment type is declined_event' do
          let_it_be(:object) do
            {
              iid: merge_request_iid,
              comment_type: 'declined_event',
              comment_id: 123,
              comment: {}
            }
          end

          it 'imports the declined_event' do
            expect_next(
              Gitlab::BitbucketServerImport::Importers::PullRequestNotes::DeclinedEvent,
              project,
              merge_request
            ).to receive(:execute).with(object[:comment])

            expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
            expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

            importer.execute
          end
        end

        context 'when comment type is inline' do
          let_it_be(:object) do
            {
              iid: merge_request_iid,
              comment_type: 'inline',
              comment_id: 123,
              comment: {}
            }
          end

          it 'imports the inline comment' do
            expect_next(
              Gitlab::BitbucketServerImport::Importers::PullRequestNotes::Inline,
              project,
              merge_request
            ).to receive(:execute).with(object[:comment])

            expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
            expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

            importer.execute
          end
        end

        context 'when comment type is standalone_notes' do
          let_it_be(:object) do
            {
              iid: merge_request_iid,
              comment_type: 'standalone_notes',
              comment_id: 123,
              comment: {}
            }
          end

          it 'imports the standalone_notes comment' do
            expect_next(
              Gitlab::BitbucketServerImport::Importers::PullRequestNotes::StandaloneNotes,
              project,
              merge_request
            ).to receive(:execute).with(object[:comment])

            expect_log(stage: 'import_pull_request_note', message: 'starting', iid: merge_request_iid)
            expect_log(stage: 'import_pull_request_note', message: 'finished', iid: merge_request_iid)

            importer.execute
          end
        end
      end
    end

    context 'when the project has been marked as failed' do
      before do
        project.import_state.mark_as_failed('error')
      end

      include_examples 'import is skipped'
    end

    context 'when the import data does not have credentials' do
      before do
        project.import_data.credentials = nil
        project.import_data.save!
      end

      include_examples 'import is skipped'
    end

    context 'when the import data does not have data' do
      before do
        project.import_data.data = nil
        project.import_data.save!
      end

      include_examples 'import is skipped'
    end
  end
end
