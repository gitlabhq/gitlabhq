# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::ReviewImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) do
    create(:project, :with_import_url, :import_user_mapping_enabled, import_type: Import::SOURCE_GITHUB)
  end

  let_it_be(:source_user) do
    create(
      :import_source_user,
      source_user_identifier: 999,
      source_hostname: project.import_url,
      import_type: Import::SOURCE_GITHUB,
      namespace: project.root_ancestor
    )
  end

  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }
  let(:submitted_at) { Time.new(2017, 1, 1, 12).utc }

  let(:client_double) do
    instance_double(
      'Gitlab::GithubImport::Client',
      user: { id: 999, login: 'author', email: 'author@email.com' }
    )
  end

  let(:user_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  before do
    allow(client_double).to receive_message_chain(:octokit, :last_response, :headers).and_return({ etag: nil })
  end

  subject { described_class.new(review, project, client_double) }

  shared_examples 'imports a reviewer for the Merge Request' do
    it 'creates reviewer for the Merge Request' do
      expect { subject.execute }.to change { MergeRequestReviewer.count }.by(1)

      expect(merge_request.reviewers).to contain_exactly(author)
    end

    context 'when add_reviewer option is false' do
      it 'does not change Merge Request reviewers' do
        expect { subject.execute(add_reviewer: false) }.not_to change { MergeRequestReviewer.count }
      end
    end

    context 'when reviewer already exists' do
      before do
        create(
          :merge_request_reviewer,
          reviewer: author, merge_request: merge_request, state: 'unreviewed'
        )
      end

      it 'does not change Merge Request reviewers' do
        expect { subject.execute }.not_to change { MergeRequestReviewer.count }

        expect(merge_request.reviewers).to contain_exactly(author)
      end
    end

    context 'when because of concurrency an attempt of duplication appeared' do
      before do
        create(:merge_request_reviewer, merge_request: merge_request, reviewer: author)
      end

      it 'does not change Merge Request reviewers', :aggregate_failures do
        expect(MergeRequestReviewer).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
        expect { subject.execute }.not_to change { MergeRequestReviewer.count }
        expect(merge_request.reviewers).to contain_exactly(author)
      end
    end
  end

  shared_examples 'imports an approval for the Merge Request' do
    it 'creates an approval for the Merge Request' do
      expect { subject.execute }.to change { Approval.count }.by(1)

      expect(merge_request.approved_by_users.reload).to include(author)
      expect(merge_request.approvals.last.created_at).to eq(submitted_at)
    end
  end

  context 'when user mapping is enabled' do
    let_it_be(:author) { source_user.mapped_user }

    context 'when the review has no note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED', note: '') }

        it_behaves_like 'imports an approval for the Merge Request'
        it_behaves_like 'imports a reviewer for the Merge Request'

        it 'creates a note for the review' do
          expect { subject.execute }.to change { Note.count }.by(1)

          last_note = merge_request.notes.last
          expect(last_note.note).to eq('approved this merge request')
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
          expect(last_note.system_note_metadata.action).to eq('approved')
        end

        it 'pushes placeholder references for reviewer and system note' do
          subject.execute

          created_approval = merge_request.approvals.last
          created_reviewer = merge_request.merge_request_reviewers.last
          system_note = merge_request.notes.last

          expect(user_references).to match_array([
            ['Approval', created_approval.id, 'user_id', source_user.id],
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id],
            ['Note', system_note.id, 'author_id', source_user.id]
          ])
        end

        context 'when the user already approved the merge request' do
          before do
            create(:approval, merge_request: merge_request, user: author)
          end

          it 'does not import second approve and note' do
            expect { subject.execute }
              .to change { Note.count }.by(0)
              .and change { Approval.count }.by(0)
          end

          it 'only pushes placeholder references for reviewer' do
            subject.execute

            created_reviewer = merge_request.merge_request_reviewers.last

            expect(user_references).to match_array([
              ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id]
            ])
          end
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED', note: '') }

        it_behaves_like 'imports a reviewer for the Merge Request'

        it 'does not create note for the review' do
          expect { subject.execute }.not_to change { Note.count }
        end

        it 'only pushes placeholder references for reviewer' do
          subject.execute

          created_reviewer = merge_request.merge_request_reviewers.last

          expect(user_references).to match_array([
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id]
          ])
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED', note: '') }

        it_behaves_like 'imports a reviewer for the Merge Request'

        it 'does not create a note for the review' do
          expect { subject.execute }.not_to change { Note.count }
        end

        it 'only pushes placeholder references for reviewer' do
          subject.execute

          created_reviewer = merge_request.merge_request_reviewers.last

          expect(user_references).to match_array([
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id]
          ])
        end
      end
    end

    context 'when the review has a note text' do
      context 'when the review is "APPROVED"' do
        let(:review) { create_review(type: 'APPROVED') }

        it_behaves_like 'imports an approval for the Merge Request'
        it_behaves_like 'imports a reviewer for the Merge Request'

        it 'creates a note for the review' do
          expect { subject.execute }.to change { Note.count }.by(2)

          note = merge_request.notes.where(system: false).last
          expect(note.note).to eq("**Review:** Approved\n\nnote")
          expect(note.author).to eq(author)
          expect(note.created_at).to eq(submitted_at)

          system_note = merge_request.notes.where(system: true).last
          expect(system_note.note).to eq('approved this merge request')
          expect(system_note.author).to eq(author)
          expect(system_note.created_at).to eq(submitted_at)
          expect(system_note.system_note_metadata.action).to eq('approved')
        end

        it 'pushes placeholder references for reviewer, system note, and reviewer note' do
          subject.execute

          created_approval = merge_request.approvals.last
          created_reviewer = merge_request.merge_request_reviewers.last
          system_note = merge_request.notes.where(system: true).last
          note = merge_request.notes.where(system: false).last

          expect(user_references).to match_array([
            ['Approval', created_approval.id, 'user_id', source_user.id],
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id],
            ['Note', system_note.id, 'author_id', source_user.id],
            ['Note', note.id, 'author_id', source_user.id]
          ])
        end
      end

      context 'when the review is "COMMENTED"' do
        let(:review) { create_review(type: 'COMMENTED') }

        it 'creates a note for the review' do
          expect { subject.execute }
            .to change { Note.count }.by(1)
            .and not_change(Approval, :count)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("**Review:** Commented\n\nnote")
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
        end

        it 'pushes placeholder references for reviewer and reviewer note' do
          subject.execute

          created_reviewer = merge_request.merge_request_reviewers.last
          note = merge_request.notes.last

          expect(user_references).to match_array([
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id],
            ['Note', note.id, 'author_id', source_user.id]
          ])
        end
      end

      context 'when the review is "CHANGES_REQUESTED"' do
        let(:review) { create_review(type: 'CHANGES_REQUESTED') }

        it 'creates a note for the review' do
          expect { subject.execute }
            .to change { Note.count }.by(1)
            .and not_change(Approval, :count)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq("**Review:** Changes requested\n\nnote")
          expect(last_note.author).to eq(author)
          expect(last_note.created_at).to eq(submitted_at)
        end

        it 'pushes placeholder references for reviewer and reviewer note' do
          subject.execute

          created_reviewer = merge_request.merge_request_reviewers.last
          note = merge_request.notes.last

          expect(user_references).to match_array([
            ['MergeRequestReviewer', created_reviewer.id, 'user_id', source_user.id],
            ['Note', note.id, 'author_id', source_user.id]
          ])
        end
      end
    end
  end

  context 'when user mapping is disabled' do
    before_all do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
    end

    context 'when the review author can be mapped to a gitlab user' do
      let_it_be(:author) { create(:user, email: 'author@email.com') }

      context 'when the review has no note text' do
        context 'when the review is "APPROVED"' do
          let(:review) { create_review(type: 'APPROVED', note: '') }

          it_behaves_like 'imports an approval for the Merge Request'
          it_behaves_like 'imports a reviewer for the Merge Request'

          it 'creates a note for the review' do
            expect { subject.execute }.to change { Note.count }.by(1)

            last_note = merge_request.notes.last
            expect(last_note.note).to eq('approved this merge request')
            expect(last_note.author).to eq(author)
            expect(last_note.created_at).to eq(submitted_at)
            expect(last_note.system_note_metadata.action).to eq('approved')
          end

          context 'when the user already approved the merge request' do
            before do
              create(:approval, merge_request: merge_request, user: author)
            end

            it 'does not import second approve and note' do
              expect { subject.execute }
                .to change { Note.count }.by(0)
                .and change { Approval.count }.by(0)
            end
          end
        end

        context 'when the review is "COMMENTED"' do
          let(:review) { create_review(type: 'COMMENTED', note: '') }

          it_behaves_like 'imports a reviewer for the Merge Request'

          it 'does not create note for the review' do
            expect { subject.execute }.not_to change { Note.count }
          end
        end

        context 'when the review is "CHANGES_REQUESTED"' do
          let(:review) { create_review(type: 'CHANGES_REQUESTED', note: '') }

          it_behaves_like 'imports a reviewer for the Merge Request'

          it 'does not create a note for the review' do
            expect { subject.execute }.not_to change { Note.count }
          end
        end
      end

      context 'when the review has a note text' do
        context 'when the review is "APPROVED"' do
          let(:review) { create_review(type: 'APPROVED') }

          it_behaves_like 'imports an approval for the Merge Request'
          it_behaves_like 'imports a reviewer for the Merge Request'

          it 'creates a note for the review' do
            expect { subject.execute }.to change { Note.count }.by(2)

            note = merge_request.notes.where(system: false).last
            expect(note.note).to eq("**Review:** Approved\n\nnote")
            expect(note.author).to eq(author)
            expect(note.created_at).to eq(submitted_at)

            system_note = merge_request.notes.where(system: true).last
            expect(system_note.note).to eq('approved this merge request')
            expect(system_note.author).to eq(author)
            expect(system_note.created_at).to eq(submitted_at)
            expect(system_note.system_note_metadata.action).to eq('approved')
          end
        end

        context 'when the review is "COMMENTED"' do
          let(:review) { create_review(type: 'COMMENTED') }

          it 'creates a note for the review' do
            expect { subject.execute }
              .to change { Note.count }.by(1)
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
              .to change { Note.count }.by(1)
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
              .to change { Note.count }.by(1)

            last_note = merge_request.notes.last
            expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Approved")
            expect(last_note.author).to eq(project.creator)
            expect(last_note.created_at).to eq(submitted_at)
          end
        end

        context 'when the review is "COMMENTED"' do
          let(:review) { create_review(type: 'COMMENTED', note: '') }

          it 'creates a note for the review with *Commented by<author>*' do
            expect { subject.execute }.not_to change { Note.count }
          end
        end

        context 'when the review is "CHANGES_REQUESTED"' do
          let(:review) { create_review(type: 'CHANGES_REQUESTED', note: '') }

          it 'creates a note for the review with *Changes requested by <author>*' do
            expect { subject.execute }.not_to change { Note.count }
          end
        end
      end

      context 'when original author was deleted in github' do
        let(:review) { create_review(type: 'APPROVED', note: '', author: nil) }

        it 'creates a note for the review without the author information' do
          expect { subject.execute }
            .to change { Note.count }.by(1)

          last_note = merge_request.notes.last

          expect(last_note.note).to eq('approved this merge request')
          expect(last_note.author).to eq(Users::Internal.ghost)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when original author cannot be found on github' do
        before do
          allow(client_double).to receive(:user).and_raise(Octokit::NotFound)
        end

        let(:review) { create_review(type: 'APPROVED', note: '') }

        it 'creates a note for the review with the author username' do
          expect { subject.execute }
            .to change { Note.count }.by(1)
          last_note = merge_request.notes.last
          expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Approved")
          expect(last_note.author).to eq(project.creator)
          expect(last_note.created_at).to eq(submitted_at)
        end
      end

      context 'when the submitted_at is not provided' do
        let(:review) { create_review(type: 'APPROVED', note: '', submitted_at: nil) }

        it 'creates a note for the review without the author information' do
          expect { subject.execute }.to change { Note.count }.by(1)

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
              .to change { Note.count }.by(1)

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
              .to change { Note.count }.by(1)

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
              .to change { Note.count }.by(1)

            last_note = merge_request.notes.last

            expect(last_note.note).to eq("*Created by: author*\n\n**Review:** Changes requested\n\nnote")
            expect(last_note.author).to eq(project.creator)
            expect(last_note.created_at).to eq(submitted_at)
          end
        end
      end
    end
  end

  def create_review(type:, **extra)
    Gitlab::GithubImport::Representation::PullRequestReview.from_json_hash(
      extra.reverse_merge(
        author: { id: 999, login: 'author' },
        merge_request_id: merge_request.id,
        merge_request_iid: merge_request.iid,
        review_type: type,
        note: 'note',
        submitted_at: submitted_at.to_s
      )
    )
  end
end
