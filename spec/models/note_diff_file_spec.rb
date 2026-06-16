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

  it_behaves_like 'model with associated note' do
    let(:note) { create(:diff_note_on_commit).tap { |diff_note| diff_note.note_diff_file.destroy! } }
    let(:record_attrs) do
      {
        diff: "@@ -6,12 +6,18 @@ module Popen",
        new_path: "files/ruby/popen.rb",
        old_path: "files/ruby/popen.rb",
        a_mode: "100644",
        b_mode: "100644",
        new_file: false,
        renamed_file: false,
        deleted_file: false,
        diff_note_id: note.id
      }
    end
  end

  describe 'ensure sharding key is set' do
    let_it_be(:diff_note, freeze: false) { create(:diff_note_on_merge_request) }

    context 'when the note is keyed solely by project_id' do
      before do
        diff_note.update_column(:namespace_id, nil)
        diff_note.reload
      end

      it 'derives namespace_id from the project namespace' do
        diff_note.note_diff_file.destroy!
        new_file = described_class.create!(
          diff_note: diff_note,
          diff: "@@ -6,12 +6,18 @@ module Popen",
          new_path: "files/ruby/popen.rb",
          old_path: "files/ruby/popen.rb",
          a_mode: "100644",
          b_mode: "100644",
          new_file: false,
          renamed_file: false,
          deleted_file: false
        )

        expect(diff_note.namespace_id).to be_nil
        expect(new_file.reload.namespace_id).to eq(diff_note.project.project_namespace_id)
      end
    end
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

  describe '#raw_diff_file' do
    context 'when the diff note has a valid original_position' do
      it 'returns a Gitlab::Diff::File' do
        expect(note_diff_file.raw_diff_file).to be_a(Gitlab::Diff::File)
      end
    end

    context 'when the diff note has a nil original_position (corrupt YAML in the column)' do
      before do
        allow(diff_note).to receive(:original_position).and_return(nil)
      end

      it 'returns nil without raising', :aggregate_failures do
        expect { note_diff_file.raw_diff_file }.not_to raise_error
        expect(note_diff_file.raw_diff_file).to be_nil
      end
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
