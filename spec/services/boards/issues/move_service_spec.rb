require 'spec_helper'

describe Boards::Issues::MoveService do
  describe '#execute' do
    context 'when parent is a project' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:board1) { create(:board, project: project) }
      let(:board2) { create(:board, project: project) }

      let(:bug) { create(:label, project: project, name: 'Bug') }
      let(:development) { create(:label, project: project, name: 'Development') }
      let(:testing)  { create(:label, project: project, name: 'Testing') }
      let(:regression) { create(:label, project: project, name: 'Regression') }

      let!(:list1)   { create(:list, board: board1, label: development, position: 0) }
      let!(:list2)   { create(:list, board: board1, label: testing, position: 1) }
      let!(:closed)  { create(:closed_list, board: board1) }

      let(:parent) { project }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues move service'
    end

    context 'when parent is a group' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:board1) { create(:board, group: group) }
      let(:board2) { create(:board, group: group) }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing)  { create(:group_label, group: group, name: 'Testing') }
      let(:regression) { create(:group_label, group: group, name: 'Regression') }

      let!(:list1)   { create(:list, board: board1, label: development, position: 0) }
      let!(:list2)   { create(:list, board: board1, label: testing, position: 1) }
      let!(:closed)  { create(:closed_list, board: board1) }

      let(:parent) { group }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues move service'
    end
  end
end
