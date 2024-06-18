# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group recent issue boards', feature_category: :portfolio_management do
  include GraphqlHelpers

  it_behaves_like 'querying a GraphQL type recent boards' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent) { create(:group, :public) }
    let_it_be(:board) { create(:board, resource_parent: parent, name: 'test group board') }
    let(:board_type) { 'group' }
  end
end
