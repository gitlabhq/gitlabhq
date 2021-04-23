# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::BuildService do
  include AdminModeHelper

  let(:note) { create(:discussion_note_on_issue) }
  let(:project) { note.project }
  let(:author) { note.author }
  let(:user) { author }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:mr_note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: note.author) }
  let(:base_params) { { note: 'Test' } }
  let(:params) { {} }

  subject(:new_note) { described_class.new(project, user, base_params.merge(params)).execute }

  describe '#execute' do
    context 'when in_reply_to_discussion_id is specified' do
      let(:params) { { in_reply_to_discussion_id: note.discussion_id } }

      context 'when a note with that original discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
          expect(new_note.resolved?).to be_falsey
        end

        context 'when discussion is resolved' do
          let(:params) { { in_reply_to_discussion_id: mr_note.discussion_id } }

          before do
            mr_note.resolve!(author)
          end

          it 'resolves the note' do
            expect(new_note).to be_valid
            expect(new_note.resolved?).to be_truthy
          end
        end
      end

      context 'when a note with that discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
        end
      end

      context 'when no note with that discussion ID exists' do
        let(:params) { { in_reply_to_discussion_id: 'foo' } }

        it 'sets an error' do
          expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
        end
      end

      context 'when user has no access to discussion' do
        let(:user) { create(:user) }

        it 'sets an error' do
          expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
        end
      end

      context 'personal snippet note' do
        def reply(note, user = nil)
          user ||= create(:user)

          described_class.new(nil,
                              user,
                              note: 'Test',
                              in_reply_to_discussion_id: note.discussion_id).execute
        end

        let(:snippet_author) { create(:user) }

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
          let(:snippet) { create(:personal_snippet, :private, author: snippet_author) }
          let(:note) { create(:discussion_note_on_personal_snippet, noteable: snippet) }

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
          let(:snippet) { create(:personal_snippet, :internal, author: snippet_author) }
          let(:note) { create(:discussion_note_on_personal_snippet, noteable: snippet) }

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
            new_note = reply(note, create(:user, :external))

            expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
          end
        end
      end
    end

    context 'when replying to individual note' do
      let(:note) { create(:note_on_issue) }
      let(:params) { { in_reply_to_discussion_id: note.discussion_id } }

      it 'sets the note up to be in reply to that note' do
        expect(new_note).to be_valid
        expect(new_note).to be_a(DiscussionNote)
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end

      context 'when noteable does not support replies' do
        let(:note) { create(:note_on_commit) }

        it 'builds another individual note' do
          expect(new_note).to be_valid
          expect(new_note).to be_a(Note)
          expect(new_note.discussion_id).not_to eq(note.discussion_id)
        end
      end
    end

    context 'confidential comments' do
      before do
        project.add_reporter(author)
      end

      context 'when replying to a confidential comment' do
        let(:note) { create(:note_on_issue, confidential: true) }
        let(:params) { { in_reply_to_discussion_id: note.discussion_id, confidential: false } }

        context 'when the user can read confidential comments' do
          it '`confidential` param is ignored and set to `true`' do
            expect(new_note.confidential).to be_truthy
          end
        end

        context 'when the user cannot read confidential comments' do
          let(:user) { create(:user) }

          it 'returns `Discussion to reply to cannot be found` error' do
            expect(new_note.errors.added?(:base, "Discussion to reply to cannot be found")).to be true
          end
        end
      end

      context 'when replying to a public comment' do
        let(:note) { create(:note_on_issue, confidential: false) }
        let(:params) { { in_reply_to_discussion_id: note.discussion_id, confidential: true } }

        it '`confidential` param is ignored and set to `false`' do
          expect(new_note.confidential).to be_falsey
        end
      end

      context 'when creating a new comment' do
        context 'when the `confidential` note flag is set to `true`' do
          context 'when the user is allowed (reporter)' do
            let(:params) { { confidential: true, noteable: merge_request } }

            it 'note `confidential` flag is set to `true`' do
              expect(new_note.confidential).to be_truthy
            end
          end

          context 'when the user is allowed (issuable author)' do
            let(:user) { create(:user) }
            let(:issue) { create(:issue, author: user) }
            let(:params) { { confidential: true, noteable: issue } }

            it 'note `confidential` flag is set to `true`' do
              expect(new_note.confidential).to be_truthy
            end
          end

          context 'when the user is allowed (admin)' do
            before do
              enable_admin_mode!(admin)
            end

            let(:admin) { create(:admin) }
            let(:params) { { confidential: true, noteable: merge_request } }

            it 'note `confidential` flag is set to `true`' do
              expect(new_note.confidential).to be_truthy
            end
          end

          context 'when the user is not allowed' do
            let(:user) { create(:user) }
            let(:params) { { confidential: true, noteable: merge_request } }

            it 'note `confidential` flag is set to `false`' do
              expect(new_note.confidential).to be_falsey
            end
          end
        end

        context 'when the `confidential` note flag is set to `false`' do
          let(:params) { { confidential: false, noteable: merge_request } }

          it 'note `confidential` flag is set to `false`' do
            expect(new_note.confidential).to be_falsey
          end
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
