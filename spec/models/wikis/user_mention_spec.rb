# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wikis::UserMention, feature_category: :wiki do
  describe 'associations' do
    it { is_expected.to belong_to(:wiki_page_meta).optional(false) }
    it { is_expected.to belong_to(:note).optional(false) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'wiki_page_meta_id' }
    let_it_be(:mentionable) { create(:wiki_page_meta, container: create(:group)) }
  end
end
