# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approval, feature_category: :code_review_workflow do
  context 'presence validation' do
    it { is_expected.to validate_presence_of(:merge_request_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context 'uniqueness validation' do
    let!(:existing_record) { create(:approval) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:merge_request_id]) }
  end

  describe '.with_invalid_patch_id_sha' do
    let(:patch_id_sha) { 'def456' }
    let!(:approval_1) { create(:approval, patch_id_sha: 'abc123') }
    let!(:approval_2) { create(:approval, patch_id_sha: nil) }
    let!(:approval_3) { create(:approval, patch_id_sha: patch_id_sha) }

    it 'returns approvals with patch_id_sha not matching specified patch_id_sha' do
      expect(described_class.with_invalid_patch_id_sha(patch_id_sha))
        .to match_array([approval_1, approval_2])
    end
  end
end
