require 'spec_helper'

describe Boards::Lists::ListService do
  describe '#execute' do
    context 'when board parent is a project' do
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }
      let(:label) { create(:label, project: project) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:service) { described_class.new(project, double) }

      it_behaves_like 'lists list service'
    end

    context 'when board parent is a group' do
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:label) { create(:group_label, group: group) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:service) { described_class.new(group, double) }

      it_behaves_like 'lists list service'
    end
  end
end
