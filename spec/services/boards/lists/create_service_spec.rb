# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::CreateService, feature_category: :portfolio_management do
  context 'when board parent is a project' do
    let_it_be(:parent) { create(:project) }
    let_it_be(:board) { create(:board, project: parent) }
    let_it_be(:label) { create(:label, project: parent, name: 'in-progress') }

    it_behaves_like 'board lists create service'
  end

  context 'when board parent is a group' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:board) { create(:board, group: parent) }
    let_it_be(:label) { create(:group_label, group: parent, name: 'in-progress') }

    it_behaves_like 'board lists create service'
  end

  def create_list(params)
    create(:list, params.merge(board: board))
  end
end
