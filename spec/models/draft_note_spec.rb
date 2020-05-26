# frozen_string_literal: true

require 'spec_helper'

describe DraftNote do
  include RepoHelpers

  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  describe 'validations' do
    it_behaves_like 'a valid diff positionable note', :draft_note
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:file_path).to(:diff_file).allow_nil }
    it { is_expected.to delegate_method(:file_hash).to(:diff_file).allow_nil }
    it { is_expected.to delegate_method(:file_identifier_hash).to(:diff_file).allow_nil }
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
end
