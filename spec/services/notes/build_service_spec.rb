# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::BuildService, feature_category: :team_planning do
  include AdminModeHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:note) { create(:discussion_note_on_issue, project: project) }
  let_it_be(:individual_note) { create(:note_on_issue, project: project) }
  let_it_be(:author) { note.author }
  let_it_be(:user) { author }
  let_it_be(:noteable_author) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:external) { create(:user, :external) }

  let(:base_params) { { note: 'Test' } }
  let(:params) { {} }
  let(:executing_user) { nil }

  subject(:new_note) do
    described_class
      .new(project, user, base_params.merge(params))
      .execute(executing_user: executing_user)
  end

  describe '#execute' do
    context 'when in_reply_to_discussion_id is specified' do
      let(:discussion_class) { DiscussionNote }
      let(:params) { { in_reply_to_discussion_id: note.discussion_id } }

      it_behaves_like 'building notes replying to another note'

      context 'when a note with that original discussion ID exists' do
        context 'when discussion is resolved' do
          let_it_be(:merge_request) { create(:merge_request, source_project: project) }
          let_it_be(:mr_note) { create(:discussion_note_on_merge_request, :resolved, noteable: merge_request, project: project, author: author) }

          let(:params) { { in_reply_to_discussion_id: mr_note.discussion_id } }

          it 'resolves the note' do
            expect(new_note).to be_valid
            expect(new_note.resolved?).to be_truthy
          end
        end

        context 'when noteable does not support replies' do
          let_it_be(:note) { create(:note_on_commit, project: project) }

          it 'builds another individual note' do
            expect(new_note).to be_valid
            expect(new_note).to be_a(Note)
            expect(new_note.discussion_id).not_to eq(individual_note.discussion_id)
          end
        end
      end

      context 'personal snippet note' do
        def reply(note, user = other_user)
          described_class.new(
            nil,
            user,
            note: 'Test',
            in_reply_to_discussion_id: note.discussion_id
          ).execute
        end

        let_it_be(:snippet_author) { noteable_author }

        context 'when a snippet is public' do
          it 'creates a reply note' do
            snippet = create(:personal_snippet, :public)
            note = create(:discussion_note_on_personal_snippet, noteable: snippet)

            new_note = reply(note)

            expect(new_note).to be_valid
            expect(new_note.in_reply_to?(note)).to be_truthy
          end
        end

        context 'when a snippet is private' do
          let_it_be(:snippet) { create(:personal_snippet, :private, author: snippet_author) }
          let_it_be(:note) { create(:discussion_note_on_personal_snippet, noteable: snippet) }

          it 'creates a reply note when the author replies' do
            new_note = reply(note, snippet_author)

            expect(new_note).to be_valid
            expect(new_note.in_reply_to?(note)).to be_truthy
          end

          it 'sets an error when another user replies' do
            new_note = reply(note)

            expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
          end
        end

        context 'when a snippet is internal' do
          let_it_be(:snippet) { create(:personal_snippet, :internal, author: snippet_author) }
          let_it_be(:note) { create(:discussion_note_on_personal_snippet, noteable: snippet) }

          it 'creates a reply note when the author replies' do
            new_note = reply(note, snippet_author)

            expect(new_note).to be_valid
            expect(new_note.in_reply_to?(note)).to be_truthy
          end

          it 'creates a reply note when a regular user replies' do
            new_note = reply(note)

            expect(new_note).to be_valid
            expect(new_note.in_reply_to?(note)).to be_truthy
          end

          it 'sets an error when an external user replies' do
            new_note = reply(note, external)

            expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
          end
        end
      end
    end

    context 'confidential comments' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:guest) { create(:user) }
      let_it_be(:reporter) { create(:user) }
      let_it_be(:admin) { create(:admin) }
      let_it_be(:issuable_assignee) { other_user }
      let_it_be(:issue) do
        create(:issue, project: project, author: noteable_author, assignees: [issuable_assignee])
      end

      before do
        project.add_guest(guest)
        project.add_reporter(reporter)
      end

      context 'when creating a new confidential comment' do
        let(:params) { { internal: true, noteable: issue } }

        shared_examples 'user allowed to set comment as confidential' do
          it { expect(new_note.confidential).to be_truthy }
        end

        shared_examples 'user not allowed to set comment as confidential' do
          it { expect(new_note.confidential).to be_falsey }
        end

        context 'reporter' do
          let(:user) { reporter }

          it_behaves_like 'user allowed to set comment as confidential'
        end

        context 'issuable author' do
          let(:user) { noteable_author }

          it_behaves_like 'user not allowed to set comment as confidential'
        end

        context 'issuable assignee' do
          let(:user) { issuable_assignee }

          it_behaves_like 'user not allowed to set comment as confidential'
        end

        context 'admin' do
          before do
            enable_admin_mode!(admin)
          end

          let(:user) { admin }

          it_behaves_like 'user allowed to set comment as confidential'
        end

        context 'external' do
          let(:user) { external }

          it_behaves_like 'user not allowed to set comment as confidential'
        end

        context 'guest' do
          let(:user) { guest }

          it_behaves_like 'user not allowed to set comment as confidential'
        end

        context 'when using the deprecated `confidential` parameter' do
          let(:params) { { internal: true, noteable: issue } }

          shared_examples 'user allowed to set comment as confidential' do
            it { expect(new_note.confidential).to be_truthy }
          end
        end
      end

      context 'when replying to a confidential comment' do
        let_it_be(:note) { create(:note_on_issue, confidential: true, noteable: issue, project: project) }

        let(:params) { { in_reply_to_discussion_id: note.discussion_id, confidential: false } }

        shared_examples 'returns `Discussion to reply to cannot be found` error' do
          it do
            expect(new_note.errors.added?(:base, "Discussion to reply to cannot be found")).to be true
          end
        end

        shared_examples 'confidential set to `true`' do
          it '`confidential` param is ignored to match the parent note confidentiality' do
            expect(new_note.confidential).to be_truthy
          end
        end

        context 'with reporter access' do
          let(:user) { reporter }

          it_behaves_like 'confidential set to `true`'
        end

        context 'with admin access' do
          let(:user) { admin }

          before do
            enable_admin_mode!(admin)
          end

          it_behaves_like 'confidential set to `true`'
        end

        context 'with noteable author' do
          let(:user) { note.noteable.author }

          it_behaves_like 'returns `Discussion to reply to cannot be found` error'
        end

        context 'with noteable assignee' do
          let(:user) { issuable_assignee }

          it_behaves_like 'returns `Discussion to reply to cannot be found` error'
        end

        context 'with guest access' do
          let(:user) { guest }

          it_behaves_like 'returns `Discussion to reply to cannot be found` error'
        end

        context 'with external user' do
          let(:user) { external }

          it_behaves_like 'returns `Discussion to reply to cannot be found` error'
        end
      end

      context 'when replying to a public comment' do
        let_it_be(:note) { create(:note_on_issue, confidential: false, noteable: issue, project: project) }

        let(:params) { { in_reply_to_discussion_id: note.discussion_id, confidential: true } }

        it '`confidential` param is ignored and set to `false`' do
          expect(new_note.confidential).to be_falsey
        end
      end
    end

    context 'when noteable is not set' do
      let(:params) { { noteable_type: note.noteable_type, noteable_id: note.noteable_id } }

      it 'builds a note without saving it' do
        expect(new_note).to be_valid
        expect(new_note).not_to be_persisted
      end
    end
  end
end
