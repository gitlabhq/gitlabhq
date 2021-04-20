# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::ListService do
  let(:user) { create(:user) }

  describe '#execute' do
    let(:service) { described_class.new(parent, user) }

    context 'when board parent is a project' do
      let_it_be(:project) { create(:project) }
      let_it_be_with_reload(:board) { create(:board, project: project) }
      let_it_be(:label) { create(:label, project: project) }
      let_it_be(:list) { create(:list, board: board, label: label) }
      let_it_be(:unrelated_list) { create(:list) }

      let(:parent) { project }

      it_behaves_like 'lists list service'
    end

    context 'when board parent is a group' do
      let_it_be(:group) { create(:group) }
      let_it_be_with_reload(:board) { create(:board, group: group) }
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:list) { create(:list, board: board, label: label) }
      let_it_be(:unrelated_list) { create(:list) }

      let(:parent) { group }

      it_behaves_like 'lists list service'
    end

    def create_backlog_list(board)
      create(:backlog_list, board: board)
    end
  end
end
