# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CopyService do
  describe '#initialize' do
    let_it_be(:noteable) { create(:issue) }

    it 'validates that we cannot copy notes to the same Noteable' do
      expect { described_class.new(nil, noteable, noteable) }.to raise_error(ArgumentError)
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:from_project) { create(:project, :public, group: group) }
    let_it_be(:to_project) { create(:project, :public, group: group) }

    let(:from_noteable) { create(:issue, project: from_project) }
    let(:to_noteable) { create(:issue, project: to_project) }

    subject(:execute_service) { described_class.new(user, from_noteable, to_noteable).execute }

    context 'rewriting the note body' do
      context 'simple notes' do
        let!(:notes) do
          [
            create(:note, noteable: from_noteable, project: from_noteable.project,
                          created_at: 2.weeks.ago, updated_at: 1.week.ago),
            create(:note, noteable: from_noteable, project: from_noteable.project),
            create(:note, system: true, noteable: from_noteable, project: from_noteable.project)
          ]
        end

        it 'rewrites existing notes in valid order' do
          execute_service

          expect(to_noteable.notes.order('id ASC').pluck(:note).first(3)).to eq(notes.map(&:note))
        end

        it 'copies all the issue notes' do
          execute_service

          expect(to_noteable.notes.count).to eq(3)
        end

        it 'does not change the note attributes' do
          execute_service

          new_note = to_noteable.notes.first

          expect(new_note).to have_attributes(
            note: notes.first.note,
            author: notes.first.author
          )
        end

        it 'copies the award emojis' do
          create(:award_emoji, awardable: notes.first, name: 'thumbsup')

          execute_service

          new_award_emoji = to_noteable.notes.first.award_emoji.first

          expect(new_award_emoji.name).to eq('thumbsup')
        end

        it 'copies system_note_metadata for system note' do
          system_note_metadata = create(:system_note_metadata, note: notes.last)

          execute_service

          new_note = to_noteable.notes.last

          aggregate_failures do
            expect(new_note.system_note_metadata.action).to eq(system_note_metadata.action)
            expect(new_note.system_note_metadata.id).not_to eq(system_note_metadata.id)
          end
        end

        it 'returns success' do
          aggregate_failures do
            expect(execute_service).to be_kind_of(ServiceResponse)
            expect(execute_service).to be_success
          end
        end
      end

      context 'notes with mentions' do
        let!(:note_with_mention) { create(:note, noteable: from_noteable, author: from_noteable.author, project: from_noteable.project, note: "note with mention #{user.to_reference}") }
        let!(:note_with_no_mention) { create(:note, noteable: from_noteable, author: from_noteable.author, project: from_noteable.project, note: "note without mention") }

        it 'saves user mentions with actual mentions for new issue' do
          execute_service

          aggregate_failures do
            expect(to_noteable.user_mentions.first.mentioned_users_ids).to match_array([user.id])
            expect(to_noteable.user_mentions.count).to eq(1)
          end
        end
      end

      context 'notes with reference' do
        let(:other_issue) { create(:issue, project: from_noteable.project) }
        let(:merge_request) { create(:merge_request) }
        let(:text) { "See ##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}" }
        let!(:note) { create(:note, noteable: from_noteable, note: text, project: from_noteable.project) }

        it 'rewrites the references correctly' do
          execute_service

          new_note = to_noteable.notes.first

          expected_text = "See #{other_issue.project.path}##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}"

          aggregate_failures do
            expect(new_note.note).to eq(expected_text)
            expect(new_note.author).to eq(note.author)
          end
        end
      end

      context 'notes with upload' do
        let(:uploader) { build(:file_uploader, project: from_noteable.project) }
        let(:text) { "Simple text with image: #{uploader.markdown_link} "}
        let!(:note) { create(:note, noteable: from_noteable, note: text, project: from_noteable.project) }

        it 'rewrites note content correctly' do
          execute_service
          new_note = to_noteable.notes.first

          aggregate_failures do
            expect(note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
            expect(new_note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
            expect(note.note).not_to eq(new_note.note)
            expect(note.note_html).not_to eq(new_note.note_html)
          end
        end
      end

      context 'discussion notes' do
        let(:note) { create(:note, noteable: from_noteable, note: 'sample note', project: from_noteable.project) }
        let!(:discussion) { create(:discussion_note_on_issue, in_reply_to: note, note: 'reply to sample note') }

        it 'rewrites discussion correctly' do
          execute_service

          aggregate_failures do
            expect(to_noteable.notes.count).to eq(from_noteable.notes.count)
            expect(to_noteable.notes.where(discussion_id: discussion.discussion_id).count).to eq(0)
            expect(from_noteable.notes.where(discussion_id: discussion.discussion_id).count).to eq(1)
          end
        end
      end
    end
  end
end
