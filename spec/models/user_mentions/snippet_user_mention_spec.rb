# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetUserMention, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:snippet) }
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'snippet_id' }
    let_it_be(:mentionable) { create(:project_snippet) }
  end
end
