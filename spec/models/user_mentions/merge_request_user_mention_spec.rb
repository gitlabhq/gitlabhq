# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestUserMention, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'merge_request_id' }
    let_it_be(:mentionable) { create(:merge_request) }
  end
end
