# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitUserMention, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'commit_id' }
    let_it_be(:mentionable) { create(:commit, project: create(:project), commit_message: 'test') }
  end
end
