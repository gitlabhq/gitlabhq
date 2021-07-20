# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestReviewImporter, :clean_gitlab_redis_cache do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:merge_request) { create(:merge_request) }

  let(:project) { merge_request.project }
  let(:client_double) { double(user: double(id: 999, login: 'author', email: 'author@email.com')) }
  let(:submitted_at) { Time.new(2017, 1, 1, 12, 00).utc }

  subject { described_class.new(review, project, client_double) }

  context 'when the review author can be mapped to a gitlab user' do
    let_it_be(:author) { create(:user, email: 'author@email.com') }

    context 'when the review has no note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED', note: '') }

        it 'creates a note for the review and approves the Merge Request' do
          expect { subject.execute }
            .to change(Note, :count).by(1)
            .and change(Approval, :count).by(1)

          last_note = merge_request.notes.last
          expect(last_note.note).to eq('approved this merge request')
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
          expect(last_note.system_note_metadata.action).to eq('approved')

          expect(merge_request.approved_by_users.reload).to include(author)
          expect(merge_request.approvals.last.created_at).to eq(submitted_at)
        end

        it 'does nothing if the user already approved the merge request' do
          create(:approval, merge_request: merge_request, user: author)

          expect { subject.execute }
            .to change(Note, :count).by(0)
            .and change(Approval, :count).by(0)
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED', note: '') }

        it 'creates a note for the review' do
          expect { subject.execute }.not_to change(Note, :count)
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED', note: '') }

        it 'creates a note for the review' do
          expect { subject.execute }.not_to change(Note, :count)
        end
      end
    end

    context 'when the review has a note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED') }

        it 'creates a note for the review' do
          expect { subject.execute }
            .to change(Note, :count).by(2)
            .and change(Approval, :count).by(1)

          note = merge_request.notes.where(system: false).last
          expect(note.note).to eq("**Review:** Approved\n\nnote")
          expect(note.author).to eq(author)
          expect(note.created_at).to eq(submitted_at)

          system_note = merge_request.notes.where(system: true).last
          expect(system_note.note).to eq('approved this merge request')
          expect(system_note.author).to eq(author)
          expect(system_note.created_at).to eq(submitted_at)
          expect(system_note.system_note_metadata.action).to eq('approved')

          expect(merge_request.approved_by_users.reload).to include(author)
          expect(merge_request.approvals.last.created_at).to eq(submitted_at)
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED') }

        it 'creates a note for the review' do
          expect { subject.execute }
            .to change(Note, :count).by(1)
            .and not_change(Approval, :count)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("**Review:** Commented\n\nnote")
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED') }

        it 'creates a note for the review' do
          expect { subject.execute }
            .to change(Note, :count).by(1)
            .and not_change(Approval, :count)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("**Review:** Changes requested\n\nnote")
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end
    end
  end

  context 'when the review author cannot be mapped to a gitlab user' do
    context 'when the review has no note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED', note: '') }

        it 'creates a note for the review with *Approved by by<author>*' do
          expect { subject.execute }
            .to change(Note, :count).by(1)

          last_note = merge_request.notes.last
          expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Approved")
          expect(last_note.author).to eq(project.creator)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED', note: '') }

        it 'creates a note for the review with *Commented by<author>*' do
          expect { subject.execute }.not_to change(Note, :count)
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED', note: '') }

        it 'creates a note for the review with *Changes requested by <author>*' do
          expect { subject.execute }.not_to change(Note, :count)
        end
      end
    end

    context 'when original author was deleted in github' do
      let(:review) { create_review(type: 'APPROVED', note: '', author: nil) }

      it 'creates a note for the review without the author information' do
        expect { subject.execute }
          .to change(Note, :count).by(1)

        last_note = merge_request.notes.last
        expect(last_note.note).to eq('**Review:** Approved')
        expect(last_note.author).to eq(project.creator)
        expect(last_note.created_at).to eq(submitted_at)
      end
    end

    context 'when the submitted_at is not provided' do
      let(:review) { create_review(type: 'APPROVED', note: '', submitted_at: nil) }

      it 'creates a note for the review without the author information' do
        expect { subject.execute }.to change(Note, :count).by(1)

        last_note = merge_request.notes.last

        expect(last_note.created_at)
          .to be_within(1.second).of(merge_request.updated_at)
      end
    end

    context 'when the review has a note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED') }

        it 'creates a note for the review with *Approved by by<author>*' do
          expect { subject.execute }
            .to change(Note, :count).by(1)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Approved\n\nnote")
          expect(last_note.author).to eq(project.creator)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED') }

        it 'creates a note for the review with *Commented by<author>*' do
          expect { subject.execute }
            .to change(Note, :count).by(1)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Commented\n\nnote")
          expect(last_note.author).to eq(project.creator)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED') }

        it 'creates a note for the review with *Changes requested by <author>*' do
          expect { subject.execute }
            .to change(Note, :count).by(1)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Changes requested\n\nnote")
          expect(last_note.author).to eq(project.creator)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end
    end
  end

  def create_review(type:, **extra)
    Gitlab::GithubImport::Representation::PullRequestReview.from_json_hash(
      extra.reverse_merge(
        author: { id: 999, login: 'author' },
        merge_request_id: merge_request.id,
        review_type: type,
        note: 'note',
        submitted_at: submitted_at.to_s
      )
    )
  end
end
