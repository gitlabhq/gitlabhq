# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::ApprovedEvent, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }
  let_it_be(:approved_event) do
    {
      id: 4,
      approver_name: 'John Approvals',
      approver_username: 'pull_request_author',
      approver_email: 'pull_request_author@example.org',
      created_at: now
    }
  end

  let_it_be(:source_user) { generate_source_user(project, approved_event[:approver_username]) }

  let(:cached_references) { placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id) }

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'pushes placeholder references' do
      importer.execute(approved_event)

      expect(cached_references).to contain_exactly(
        ['Approval', instance_of(Integer), 'user_id', source_user.id],
        ['MergeRequestReviewer', instance_of(Integer), 'user_id', source_user.id],
        ['Note', instance_of(Integer), 'author_id', source_user.id]
      )
    end

    context 'if approval is not persisted' do
      before do
        allow(Approval).to receive(:create).and_return(Approval.new)
      end

      it 'does not push placeholder references for the approval or approval note' do
        importer.execute(approved_event)

        expect(cached_references).to contain_exactly(
          ['MergeRequestReviewer', instance_of(Integer), 'user_id', source_user.id]
        )
      end
    end

    it 'creates the approval, reviewer and approval note' do
      expect { importer.execute(approved_event) }
        .to change { merge_request.approvals.count }.from(0).to(1)
        .and change { merge_request.notes.count }.from(0).to(1)
        .and change { merge_request.reviewers.count }.from(0).to(1)

      approval = merge_request.approvals.first

      expect(approval.user_id).to eq(source_user.mapped_user_id)
      expect(approval.created_at).to eq(now)

      note = merge_request.notes.first

      expect(note.note).to eq('approved this merge request')
      expect(note.author_id).to eq(source_user.mapped_user_id)
      expect(note.system).to be_truthy
      expect(note.created_at).to eq(now)

      reviewer = merge_request.reviewers.first

      expect(reviewer.id).to eq(source_user.mapped_user_id)
    end

    it 'logs its progress' do
      expect_log(stage: 'import_approved_event', message: 'starting', iid: merge_request.iid, event_id: 4)
      expect_log(stage: 'import_approved_event', message: 'finished', iid: merge_request.iid, event_id: 4)

      importer.execute(approved_event)
    end

    context 'when approved event has no associated approver' do
      let(:approved_event) { super().merge(approver_username: nil) }

      it 'does not set an approver' do
        expect_log(
          stage: 'import_approved_event',
          message: 'skipped due to missing user',
          iid: merge_request.iid,
          event_id: 4
        )

        expect { importer.execute(approved_event) }
          .to not_change { merge_request.approvals.count }
          .and not_change { merge_request.notes.count }
          .and not_change { merge_request.reviewers.count }

        expect(merge_request.approvals).to be_empty
      end
    end

    context 'when user contribution mapping is disabled' do
      let_it_be(:pull_request_author) do
        create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org')
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'finds the user based on email' do
        importer.execute(approved_event)

        approval = merge_request.approvals.first

        expect(approval.user_id).to eq(pull_request_author.id)
      end

      it 'creates the approval, reviewer and approval note' do
        expect { importer.execute(approved_event) }
          .to change { merge_request.approvals.count }.from(0).to(1)
          .and change { merge_request.notes.count }.from(0).to(1)
          .and change { merge_request.reviewers.count }.from(0).to(1)

        approval = merge_request.approvals.first
        expect(approval.user_id).to eq(pull_request_author.id)

        note = merge_request.notes.first
        expect(note.author_id).to eq(pull_request_author.id)

        reviewer = merge_request.reviewers.first
        expect(reviewer.id).to eq(pull_request_author.id)
      end

      it 'does not push placeholder references' do
        importer.execute(approved_event)

        expect(cached_references).to be_empty
      end

      context 'when no users match email' do
        let(:approved_event) { super().merge(approver_email: 'anotheremail@example.com') }

        it 'does not set an approver' do
          expect_log(
            stage: 'import_approved_event',
            message: 'skipped due to missing user',
            iid: merge_request.iid,
            event_id: 4
          )

          expect { importer.execute(approved_event) }
            .to not_change { merge_request.approvals.count }
            .and not_change { merge_request.notes.count }
            .and not_change { merge_request.reviewers.count }

          expect(merge_request.approvals).to be_empty
        end
      end
    end
  end
end
