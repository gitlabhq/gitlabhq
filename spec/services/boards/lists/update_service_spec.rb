# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::UpdateService, factory_default: :keep, feature_category: :planning_views do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create_default(:project, :private) }

  describe '#execute' do
    let(:service) { described_class.new(board.resource_parent, user, params) }

    shared_examples 'a board list update' do
      context 'when position parameter is present' do
        let(:params) { { position: 1 } }

        it_behaves_like 'moving list'
      end

      context 'when collapsed parameter is present' do
        let(:params) { { collapsed: true } }

        it_behaves_like 'updating list preferences'
      end

      context 'when position and collapsed are both present' do
        let(:params) { { collapsed: true, position: 1 } }

        it_behaves_like 'moving list'
        it_behaves_like 'updating list preferences'
      end
    end

    context 'for projects' do
      let_it_be(:board) { create(:board, project: project) }
      let_it_be_with_reload(:list) { create(:list, board: board, position: 0) }
      let_it_be(:list2) { create(:list, board: board, position: 1) }

      it_behaves_like 'a board list update'
    end

    context 'for groups' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:board) { create(:board, group: group) }
      let_it_be_with_reload(:list) { create(:list, board: board, position: 0) }
      let_it_be(:list2) { create(:list, board: board, position: 1) }

      it_behaves_like 'a board list update'
    end
  end
end
