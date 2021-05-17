# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Board do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#order_by_name_asc' do
    let!(:board_B) { create(:board, project: project, name: 'B') }
    let!(:board_C) { create(:board, project: project, name: 'C') }
    let!(:board_a) { create(:board, project: project, name: 'a') }
    let!(:board_A) { create(:board, project: project, name: 'A') }

    it 'returns in case-insensitive alphabetical order and then by ascending id' do
      expect(project.boards.order_by_name_asc).to eq [board_a, board_A, board_B, board_C]
    end
  end

  describe '#first_board' do
    let!(:board_B) { create(:board, project: project, name: 'B') }
    let!(:board_C) { create(:board, project: project, name: 'C') }
    let!(:board_a) { create(:board, project: project, name: 'a') }
    let!(:board_A) { create(:board, project: project, name: 'A') }

    it 'return the first case-insensitive alphabetical board as a relation' do
      expect(project.boards.first_board).to eq [board_a]
    end

    # BoardsActions#board expects this behavior
    it 'raises an error when find is done on a non-existent record' do
      expect { project.boards.first_board.find(board_A.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#disabled_for?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }

    subject { board.disabled_for?(user) }

    shared_examples 'board disabled_for?' do
      context 'when current user cannot create non backlog issues' do
        it { is_expected.to eq(true) }
      end

      context 'when user can create backlog issues' do
        before do
          board.resource_parent.add_reporter(user)
        end

        it { is_expected.to eq(false) }

        context 'when block_issue_repositioning is enabled' do
          before do
            stub_feature_flags(block_issue_repositioning: group)
          end

          it { is_expected.to eq(true) }
        end
      end
    end

    context 'for group board' do
      let_it_be(:board) { create(:board, group: group) }

      it_behaves_like 'board disabled_for?'
    end

    context 'for project board' do
      let_it_be(:board) { create(:board, project: project) }

      it_behaves_like 'board disabled_for?'
    end
  end
end
