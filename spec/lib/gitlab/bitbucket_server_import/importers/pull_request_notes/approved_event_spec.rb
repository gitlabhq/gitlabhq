# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::ApprovedEvent, feature_category: :importers do
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

  let!(:pull_request_author) do
    create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org')
  end

  let(:approved_event) do
    {
      id: 4,
      approver_username: pull_request_author.username,
      approver_email: pull_request_author.email,
      created_at: now
    }
  end

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'creates the approval, reviewer and approval note' do
      expect { importer.execute(approved_event) }
        .to change { merge_request.approvals.count }.from(0).to(1)
        .and change { merge_request.notes.count }.from(0).to(1)
        .and change { merge_request.reviewers.count }.from(0).to(1)

      approval = merge_request.approvals.first

      expect(approval.user).to eq(pull_request_author)
      expect(approval.created_at).to eq(now)

      note = merge_request.notes.first

      expect(note.note).to eq('approved this merge request')
      expect(note.author).to eq(pull_request_author)
      expect(note.system).to be_truthy
      expect(note.created_at).to eq(now)

      reviewer = merge_request.reviewers.first

      expect(reviewer.id).to eq(pull_request_author.id)
    end

    context 'when a user with a matching username does not exist' do
      before do
        pull_request_author.update!(username: 'another_username')
      end

      it 'finds the user based on email' do
        importer.execute(approved_event)

        approval = merge_request.approvals.first

        expect(approval.user).to eq(pull_request_author)
      end

      context 'when no users match email or username' do
        let_it_be(:another_author) { create(:user) }

        before do
          pull_request_author.destroy!
        end

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

    context 'if the reviewer already existed' do
      before do
        merge_request.reviewers = [pull_request_author]
        merge_request.save!
      end

      it 'does not create the reviewer record' do
        expect { importer.execute(approved_event) }.not_to change { merge_request.reviewers.count }
      end
    end

    it 'logs its progress' do
      expect_log(stage: 'import_approved_event', message: 'starting', iid: merge_request.iid, event_id: 4)
      expect_log(stage: 'import_approved_event', message: 'finished', iid: merge_request.iid, event_id: 4)

      importer.execute(approved_event)
    end
  end
end
