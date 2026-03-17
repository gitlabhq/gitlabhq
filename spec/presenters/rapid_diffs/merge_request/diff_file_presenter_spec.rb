# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::MergeRequest::DiffFilePresenter, feature_category: :code_review_workflow do
  let(:diff_file) { instance_double(Gitlab::Diff::File, file_path: 'path/to/file.rb', renamed_file?: false) }
  let(:conflicts) do
    {
      'path/to/file.rb' => {
        conflict_type: :both_modified,
        conflict_type_when_renamed: :renamed_same_file
      }
    }
  end

  describe '#conflict' do
    context 'when diff file has a conflict' do
      subject(:presenter) { described_class.new(diff_file, conflicts: conflicts) }

      it 'returns the conflict type' do
        expect(presenter.conflict).to eq(:both_modified)
      end

      context 'when diff file is renamed' do
        let(:diff_file) { instance_double(Gitlab::Diff::File, file_path: 'path/to/file.rb', renamed_file?: true) }

        it 'returns the conflict_type_when_renamed' do
          expect(presenter.conflict).to eq(:renamed_same_file)
        end
      end
    end

    context 'when diff file has no conflict' do
      let(:diff_file) { instance_double(Gitlab::Diff::File, file_path: 'other/path.rb', renamed_file?: false) }

      subject(:presenter) { described_class.new(diff_file, conflicts: conflicts) }

      it 'returns nil' do
        expect(presenter.conflict).to be_nil
      end
    end

    context 'when conflicts is nil' do
      subject(:presenter) { described_class.new(diff_file) }

      it 'returns nil' do
        expect(presenter.conflict).to be_nil
      end
    end

    context 'when conflicts is empty' do
      subject(:presenter) { described_class.new(diff_file, conflicts: {}) }

      it 'returns nil' do
        expect(presenter.conflict).to be_nil
      end
    end
  end

  describe 'delegation' do
    subject(:presenter) { described_class.new(diff_file, conflicts: conflicts) }

    it 'delegates methods to diff_file' do
      expect(presenter.file_path).to eq('path/to/file.rb')
    end
  end
end
