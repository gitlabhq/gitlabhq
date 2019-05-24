# frozen_string_literal: true

require 'spec_helper'

describe Issuable::Clone::ContentRewriter do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:project, :public, group: group) }
  let(:project2) { create(:project, :public, group: group) }

  let(:other_issue) { create(:issue, project: project1) }
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(user, original_issue, new_issue)}

  let(:description) { 'Simple text' }
  let(:original_issue) { create(:issue, description: description, project: project1) }
  let(:new_issue) { create(:issue, project: project2) }

  context 'rewriting award emojis' do
    it 'copies the award emojis' do
      create(:award_emoji, awardable: original_issue, name: 'thumbsup')
      create(:award_emoji, awardable: original_issue, name: 'thumbsdown')

      expect { subject.execute }.to change { AwardEmoji.count }.by(2)

      expect(new_issue.award_emoji.map(&:name)).to match_array(%w(thumbsup thumbsdown))
    end
  end

  context 'rewriting description' do
    before do
      subject.execute
    end

    context 'when description is a simple text' do
      it 'does not rewrite the description' do
        expect(new_issue.reload.description).to eq(original_issue.description)
      end
    end

    context 'when description contains a local reference' do
      let(:description) { "See ##{other_issue.iid}" }

      it 'rewrites the local reference correctly' do
        expected_description = "See #{project1.path}##{other_issue.iid}"

        expect(new_issue.reload.description).to eq(expected_description)
      end
    end

    context 'when description contains a cross reference' do
      let(:description) { "See #{merge_request.project.full_path}!#{merge_request.iid}" }

      it 'rewrites the cross reference correctly' do
        expected_description = "See #{merge_request.project.full_path}!#{merge_request.iid}"

        expect(new_issue.reload.description).to eq(expected_description)
      end
    end

    context 'when description contains a user reference' do
      let(:description) { "FYU #{user.to_reference}" }

      it 'works with a user reference' do
        expect(new_issue.reload.description).to eq("FYU #{user.to_reference}")
      end
    end

    context 'when description contains uploads' do
      let(:uploader) { build(:file_uploader, project: project1) }
      let(:description) { "Text and #{uploader.markdown_link}" }

      it 'rewrites uploads in the description' do
        upload = Upload.last

        expect(new_issue.description).not_to eq(description)
        expect(new_issue.description).to match(/Text and #{FileUploader::MARKDOWN_PATTERN}/)
        expect(upload.secret).not_to eq(uploader.secret)
        expect(new_issue.description).to include(upload.secret)
        expect(new_issue.description).to include(upload.path)
      end
    end
  end

  context 'rewriting notes' do
    context 'simple notes' do
      let!(:notes) do
        [
          create(:note, noteable: original_issue, project: project1,
                        created_at: 2.weeks.ago, updated_at: 1.week.ago),
          create(:note, noteable: original_issue, project: project1),
          create(:note, system: true, noteable: original_issue, project: project1)
        ]
      end
      let!(:system_note_metadata) { create(:system_note_metadata, note: notes.last) }
      let!(:award_emoji) { create(:award_emoji, awardable: notes.first, name: 'thumbsup')}

      before do
        subject.execute
      end

      it 'rewrites existing notes in valid order' do
        expect(new_issue.notes.order('id ASC').pluck(:note).first(3)).to eq(notes.map(&:note))
      end

      it 'copies all the issue notes' do
        expect(new_issue.notes.count).to eq(3)
      end

      it 'does not change the note attributes' do
        subject.execute

        new_note = new_issue.notes.first

        expect(new_note.note).to eq(notes.first.note)
        expect(new_note.author).to eq(notes.first.author)
      end

      it 'copies the award emojis' do
        subject.execute

        new_note = new_issue.notes.first
        new_note.award_emoji.first.name = 'thumbsup'
      end

      it 'copies system_note_metadata for system note' do
        new_note = new_issue.notes.last

        expect(new_note.system_note_metadata.action).to eq(system_note_metadata.action)
        expect(new_note.system_note_metadata.id).not_to eq(system_note_metadata.id)
      end
    end

    context 'notes with reference' do
      let(:text) do
        "See ##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}"
      end
      let!(:note) { create(:note, noteable: original_issue, note: text, project: project1) }

      it 'rewrites the references correctly' do
        subject.execute

        new_note = new_issue.notes.first

        expected_text = "See #{other_issue.project.path}##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}"

        expect(new_note.note).to eq(expected_text)
        expect(new_note.author).to eq(note.author)
      end
    end

    context 'notes with upload' do
      let(:uploader) { build(:file_uploader, project: project1) }
      let(:text) { "Simple text with image: #{uploader.markdown_link} "}
      let!(:note) { create(:note, noteable: original_issue, note: text, project: project1) }

      it 'rewrites note content correctly' do
        subject.execute
        new_note = new_issue.notes.first

        expect(note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
        expect(new_note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
        expect(note.note).not_to eq(new_note.note)
        expect(note.note_html).not_to eq(new_note.note_html)
      end
    end
  end
end
