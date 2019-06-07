# frozen_string_literal: true

require 'rails_helper'

describe NoteDiffFile do
  describe 'associations' do
    it { is_expected.to belong_to(:diff_note) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:diff_note) }
  end

  describe '.referencing_sha' do
    let!(:diff_note) { create(:diff_note_on_commit) }

    let(:note_diff_file) { diff_note.note_diff_file }
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
      found = described_class.referencing_sha(Gitlab::Git::BLANK_SHA, project_id: project.id)

      expect(found).to be_empty
    end
  end
end
