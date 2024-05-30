# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DraftNote, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:project)       { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  describe 'validations' do
    it_behaves_like 'a valid diff positionable note' do
      subject { build(:draft_note, merge_request: merge_request, commit_id: commit_id, position: position) }
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:file_path).to(:diff_file).allow_nil }
    it { is_expected.to delegate_method(:file_hash).to(:diff_file).allow_nil }
    it { is_expected.to delegate_method(:file_identifier_hash).to(:diff_file).allow_nil }
  end

  describe 'enums' do
    let(:note_types) do
      { Note: 0, DiffNote: 1, DiscussionNote: 2 }
    end

    it { is_expected.to define_enum_for(:note_type).with_values(**note_types) }
  end

  describe '#line_code' do
    describe 'stored line_code' do
      let(:draft_note) { build(:draft_note, merge_request: merge_request, line_code: '1234567890') }

      it 'returns stored line_code' do
        expect(draft_note.line_code).to eq('1234567890')
      end
    end

    describe 'none stored line_code' do
      let(:draft_note) { build(:draft_note, merge_request: merge_request) }

      before do
        allow(draft_note).to receive(:find_line_code).and_return('none stored line_code')
      end

      it 'returns found line_code' do
        expect(draft_note.line_code).to eq('none stored line_code')
      end
    end
  end

  describe '#diff_file' do
    let(:draft_note) { build(:draft_note, merge_request: merge_request) }

    context 'when diff_file exists' do
      it "returns an unfolded diff_file" do
        diff_file = instance_double(Gitlab::Diff::File)
        expect(draft_note.original_position).to receive(:diff_file).with(project.repository).and_return(diff_file)
        expect(diff_file).to receive(:unfold_diff_lines).with(draft_note.original_position)

        expect(draft_note.diff_file).to be diff_file
      end
    end

    context 'when diff_file does not exist' do
      it 'returns nil' do
        expect(draft_note.original_position).to receive(:diff_file).with(project.repository).and_return(nil)

        expect(draft_note.diff_file).to be_nil
      end
    end
  end

  describe '#type' do
    let(:draft_note) { build(:draft_note, merge_request: merge_request) }

    context 'when note_type is present' do
      before do
        draft_note.note_type = 'DiffNote'
      end

      it 'returns the note_type' do
        expect(draft_note.type).to eq('DiffNote')
      end
    end

    context 'when note_type is not present' do
      context 'when on_diff? is true' do
        before do
          allow(draft_note).to receive(:on_diff?).and_return(true)
        end

        it 'returns "DiffNote"' do
          expect(draft_note.type).to eq('DiffNote')
        end
      end

      context 'when on_diff? is false and discussion_id is present' do
        before do
          allow(draft_note).to receive(:on_diff?).and_return(false)
          draft_note.discussion_id = 'some_id'
        end

        it 'returns "DiscussionNote"' do
          expect(draft_note.type).to eq('DiscussionNote')
        end
      end

      context 'when on_diff? is false and discussion_id is not present' do
        before do
          allow(draft_note).to receive(:on_diff?).and_return(false)
          draft_note.discussion_id = nil
        end

        it 'returns "Note"' do
          expect(draft_note.type).to eq('Note')
        end
      end
    end
  end
end
