# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteDiffFile, feature_category: :code_review_workflow do
  let(:diff_note) { create(:diff_note_on_commit) }
  let(:note_diff_file) { diff_note.note_diff_file }

  describe 'associations' do
    it { is_expected.to belong_to(:diff_note) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:diff_note) }
  end

  describe '.referencing_sha' do
    let(:project) { diff_note.project }

    it 'finds note diff files by project and sha' do
      found = described_class.referencing_sha(diff_note.commit_id, project_id: project.id)

      expect(found).to contain_exactly(note_diff_file)
    end

    it 'excludes note diff files with the wrong project' do
      other_project = create(:project)

      found = described_class.referencing_sha(diff_note.commit_id, project_id: other_project.id)

      expect(found).to be_empty
    end

    it 'excludes note diff files with the wrong sha' do
      found = described_class.referencing_sha(Gitlab::Git::SHA1_BLANK_SHA, project_id: project.id)

      expect(found).to be_empty
    end
  end

  describe '#diff_export' do
    let_it_be(:encoded) { "b\xC3\xA5r" }
    let_it_be(:expected) { "bår" }

    before do
      note_diff_file.update!(diff: encoded)
    end

    context 'when diff can be encoded' do
      it 'force encodes the diff to UTF-8' do
        expect(note_diff_file.diff_export).to eq(expected)
        expect(note_diff_file.diff_export.encoding).to eq(Encoding::UTF_8)
      end
    end

    context 'when diff cannot be encoded' do
      it 'returns the raw diff' do
        allow(note_diff_file).to receive(:force_encode_utf8).with(encoded).and_raise(ArgumentError)

        expect(note_diff_file.diff_export).to eq(encoded)
      end
    end
  end
end
