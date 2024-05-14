# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffFileMetadataEntity, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request_with_diffs) }
  let(:diff_file) { merge_request.merge_request_diff.diffs.raw_diff_files.first }
  let(:options) { {} }
  let(:entity) { described_class.new(diff_file, options) }

  context 'as json' do
    subject { entity.as_json }

    it 'exposes the expected fields' do
      expect(subject.keys).to contain_exactly(
        :added_lines,
        :removed_lines,
        :new_path,
        :old_path,
        :new_file,
        :deleted_file,
        :submodule,
        :file_identifier_hash,
        :file_hash,
        :conflict_type
      )
    end

    it_behaves_like 'diff file with conflict_type'
  end
end
