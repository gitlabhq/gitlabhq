# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::ListService do
  let(:user) { create(:user) }

  describe '#execute' do
    let(:service) { described_class.new(parent, user) }

    shared_examples 'hidden lists' do
      let!(:list) { create(:list, board: board, label: label) }

      context 'when hide_backlog_list is true' do
        it 'hides backlog list' do
          board.update!(hide_backlog_list: true)

          expect(service.execute(board)).to match_array([board.closed_list, list])
        end
      end

      context 'when hide_closed_list is true' do
        it 'hides closed list' do
          board.update!(hide_closed_list: true)

          expect(service.execute(board)).to match_array([board.backlog_list, list])
        end
      end
    end

    context 'when board parent is a project' do
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }
      let(:label) { create(:label, project: project) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:parent) { project }

      it_behaves_like 'lists list service'
      it_behaves_like 'hidden lists'
    end

    context 'when board parent is a group' do
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:label) { create(:group_label, group: group) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:parent) { group }

      it_behaves_like 'lists list service'
      it_behaves_like 'hidden lists'
    end
  end
end
