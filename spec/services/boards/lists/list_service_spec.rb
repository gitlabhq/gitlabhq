# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::ListService do
  let(:user) { create(:user) }

  describe '#execute' do
    let(:service) { described_class.new(parent, user) }

    context 'when board parent is a project' do
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }
      let(:label) { create(:label, project: project) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:parent) { project }

      it_behaves_like 'lists list service'
    end

    context 'when board parent is a group' do
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:label) { create(:group_label, group: group) }
      let!(:list) { create(:list, board: board, label: label) }
      let(:parent) { group }

      it_behaves_like 'lists list service'
    end
  end
end
