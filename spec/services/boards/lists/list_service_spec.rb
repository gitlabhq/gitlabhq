# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::ListService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  RSpec.shared_examples 'FOSS lists only' do
    context 'when board contains a non FOSS list' do
      # This scenario may happen when there used to be an EE license and user downgraded
      let_it_be(:backlog_list) { board.lists.backlog.first }
      let_it_be(:milestone) { create(:milestone, group: group) }
      let_it_be(:assignee_list) do
        list = build(:list, board: board, user_id: user.id, list_type: List.list_types[:assignee], position: 0)
        list.save!(validate: false)
        list
      end

      let_it_be(:milestone_list) do
        list = build(:list, board: board, milestone_id: milestone.id, list_type: List.list_types[:milestone],
          position: 1)
        list.save!(validate: false)
        list
      end

      it "returns only FOSS board's lists" do
        # just making sure these non FOSS lists actually exist on the board
        expect(board.lists.with_types([List.list_types[:assignee], List.list_types[:milestone]]).count).to eq 2
        # check that the FOSS lists are not returned from the service
        expect(service.execute(board)).to match_array [backlog_list, list, board.lists.closed.first]
      end
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(parent, user) }

    context 'when board parent is a project' do
      let_it_be(:project) { create(:project, group: group) }
      let_it_be_with_reload(:board) { create(:board, project: project) }
      let_it_be(:label) { create(:label, project: project) }
      let_it_be(:list) { create(:list, board: board, label: label) }
      let_it_be(:unrelated_list) { create(:list) }

      let(:parent) { project }

      it_behaves_like 'lists list service'
      it_behaves_like 'FOSS lists only'
    end

    context 'when board parent is a group' do
      let_it_be_with_reload(:board) { create(:board, group: group) }
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:list) { create(:list, board: board, label: label) }
      let_it_be(:unrelated_list) { create(:list) }

      let(:parent) { group }

      it_behaves_like 'lists list service'
      it_behaves_like 'FOSS lists only'
    end
  end
end
