# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of boards', feature_category: :portfolio_management do
  include GraphqlHelpers

  include_context 'group and project boards query context'

  describe 'for a project' do
    let(:board_parent) { create(:project, :repository, :private) }

    it_behaves_like 'group and project boards query'
  end

  describe 'for a group' do
    let(:board_parent) { create(:group, :private) }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project boards query'
  end
end
