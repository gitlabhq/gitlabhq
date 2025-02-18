# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignUserMention, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:design) }
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions' do
    let_it_be(:mentionable_key) { 'design_id' }
    let_it_be(:mentionable) { create(:design) }
  end
end
