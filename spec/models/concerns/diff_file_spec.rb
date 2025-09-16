# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffFile, feature_category: :code_review_workflow do
  let(:file) { create(:merge_request).merge_request_diff.merge_request_diff_files.first }

  describe "to_hash" do
    it "returns a hash including all keys" do
      expect(file.to_hash.symbolize_keys.keys).to match_array(Gitlab::Git::Diff::SERIALIZE_KEYS)
    end

    context "when new_path is nil" do
      before do
        file.update_column(:new_path, nil)
      end

      it "returns the value of old_path as new_path" do
        expect(file[:new_path]).to be_nil
        expect(file.to_hash[:new_path]).to eq(file.old_path)
      end
    end
  end
end
