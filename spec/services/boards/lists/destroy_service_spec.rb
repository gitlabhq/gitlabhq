# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::DestroyService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }

  let(:list_type) { :list }

  describe '#execute' do
    context 'when board parent is a project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:board) { create(:board, project: project) }
      let_it_be(:list) { create(:list, board: board) }
      let_it_be(:closed_list) { board.lists.closed.first }

      let(:params) do
        { board: board }
      end

      let(:parent) { project }

      it_behaves_like 'lists destroy service'
    end

    context 'when board parent is a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:board) { create(:board, group: group) }
      let_it_be(:list) { create(:list, board: board) }
      let_it_be(:closed_list) { board.lists.closed.first }

      let(:params) do
        { board: board }
      end

      let(:parent) { group }

      it_behaves_like 'lists destroy service'
    end
  end
end
