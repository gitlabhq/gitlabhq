# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeData, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).inverse_of(:merge_data) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:merge_user).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:merge_request) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:merge_status) }
  end
end
