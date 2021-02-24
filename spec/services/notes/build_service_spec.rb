# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::BuildService do
  include AdminModeHelper

  let(:note) { create(:discussion_note_on_issue) }
  let(:project) { note.project }
  let(:author) { note.author }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:mr_note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: author) }

  describe '#execute' do
    context 'when in_reply_to_discussion_id is specified' do
      context 'when a note with that original discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
          expect(new_note.resolved?).to be_falsey
        end

        context 'when discussion is resolved' do
          before do
            mr_note.resolve!(author)
          end

          it 'resolves the note' do
            new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: mr_note.discussion_id).execute
            expect(new_note).to be_valid
            expect(new_note.resolved?).to be_truthy
          end
        end
      end

      context 'when a note with that discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
        end
      end

      context 'when no note with that discussion ID exists' do
        it 'sets an error' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: 'foo').execute
          expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
        end
      end

      context 'when user has no access to discussion' do
        it 'sets an error' do
          another_user = create(:user)
          new_note = described_class.new(project, another_user, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute

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

      subject { described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute }

      it 'sets the note up to be in reply to that note' do
        expect(subject).to be_valid
        expect(subject).to be_a(DiscussionNote)
        expect(subject.discussion_id).to eq(note.discussion_id)
      end

      context 'when noteable does not support replies' do
        let(:note) { create(:note_on_commit) }

        it 'builds another individual note' do
          expect(subject).to be_valid
          expect(subject).to be_a(Note)
          expect(subject.discussion_id).not_to eq(note.discussion_id)
        end
      end
    end

    context 'confidential comments' do
      before do
        project.add_reporter(author)
      end

      context 'when replying to a confidential comment' do
        let(:note) { create(:note_on_issue, confidential: true) }

        context 'when the user can read confidential comments' do
          subject do
            described_class.new(
              project,
              author,
              note: 'Test',
              in_reply_to_discussion_id: note.discussion_id,
              confidential: false
            ).execute
          end

          it '`confidential` param is ignored and set to `true`' do
            expect(subject.confidential).to be_truthy
          end
        end

        context 'when the user cannot read confidential comments' do
          let(:another_user) { create(:user) }

          subject do
            described_class.new(
              project,
              another_user,
              note: 'Test',
              in_reply_to_discussion_id: note.discussion_id,
              confidential: false
            ).execute
          end

          it 'returns `Discussion to reply to cannot be found` error' do
            expect(subject.errors.first).to include("Discussion to reply to cannot be found")
          end
        end
      end

      context 'when replying to a public comment' do
        let(:note) { create(:note_on_issue, confidential: false) }

        subject do
          described_class.new(
            project,
            author,
            note: 'Test',
            in_reply_to_discussion_id: note.discussion_id,
            confidential: true
          ).execute
        end

        it '`confidential` param is ignored and set to `false`' do
          expect(subject.confidential).to be_falsey
        end
      end

      context 'when creating a new comment' do
        context 'when the `confidential` note flag is set to `true`' do
          context 'when the user is allowed (reporter)' do
            subject { described_class.new(project, author, note: 'Test', noteable: merge_request, confidential: true).execute }

            it 'note `confidential` flag is set to `true`' do
              expect(subject.confidential).to be_truthy
            end
          end

          context 'when the user is allowed (issuable author)' do
            let(:another_user) { create(:user) }
            let(:issue) { create(:issue, author: another_user) }

            subject { described_class.new(project, another_user, note: 'Test', noteable: issue, confidential: true).execute }

            it 'note `confidential` flag is set to `true`' do
              expect(subject.confidential).to be_truthy
            end
          end

          context 'when the user is allowed (admin)' do
            before do
              enable_admin_mode!(another_user)
            end

            let(:another_user) { create(:admin) }

            subject { described_class.new(project, another_user, note: 'Test', noteable: merge_request, confidential: true).execute }

            it 'note `confidential` flag is set to `true`' do
              expect(subject.confidential).to be_truthy
            end
          end

          context 'when the user is not allowed' do
            let(:another_user) { create(:user) }

            subject { described_class.new(project, another_user, note: 'Test', noteable: merge_request, confidential: true).execute }

            it 'note `confidential` flag is set to `false`' do
              expect(subject.confidential).to be_falsey
            end
          end
        end

        context 'when the `confidential` note flag is set to `false`' do
          subject { described_class.new(project, author, note: 'Test', noteable: merge_request, confidential: false).execute }

          it 'note `confidential` flag is set to `false`' do
            expect(subject.confidential).to be_falsey
          end
        end
      end
    end

    it 'builds a note without saving it' do
      new_note = described_class.new(project,
                                    author,
                                    noteable_type: note.noteable_type,
                                    noteable_id: note.noteable_id,
                                    note: 'Test').execute
      expect(new_note).to be_valid
      expect(new_note).not_to be_persisted
    end
  end
end
