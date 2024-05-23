# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::UpdateService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }

  let!(:list) { create(:list, board: board, position: 0) }
  let!(:list2) { create(:list, board: board, position: 1) }

  describe '#execute' do
    let(:service) { described_class.new(board.resource_parent, user, params) }

    context 'when position parameter is present' do
      let(:params) { { position: 1 } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'moving list'
      end

      context 'for groups' do
        let(:group) { create(:group, :private) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'moving list'
      end
    end

    context 'when collapsed parameter is present' do
      let(:params) { { collapsed: true } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'updating list preferences'
      end

      context 'for groups' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'updating list preferences'
      end
    end

    context 'when position and collapsed are both present' do
      let(:params) { { collapsed: true, position: 1 } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'moving list'
        it_behaves_like 'updating list preferences'
      end

      context 'for groups' do
        let(:group) { create(:group, :private) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'moving list'
        it_behaves_like 'updating list preferences'
      end
    end
  end
end
