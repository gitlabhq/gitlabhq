# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueUserMention, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'issue_id' }
    let_it_be(:mentionable) { create(:issue) }
  end
end
