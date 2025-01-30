# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Board do
  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }

    it do
      is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all)
        .inverse_of(:board)
    end

    it { is_expected.to have_many(:destroyable_lists).order(list_type: :asc, position: :asc).inverse_of(:board) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }

    describe 'group and project mutually exclusive' do
      context 'when project is present' do
        subject { described_class.new(project: project) }

        it do
          is_expected.to validate_absence_of(:group)
            .with_message(_("can't be specified if a project was already provided"))
        end
      end

      context 'when project is not present' do
        it { is_expected.not_to validate_absence_of(:group) }
      end
    end
  end

  describe 'constants' do
    it { expect(described_class::RECENT_BOARDS_SIZE).to be_a(Integer) }
  end

  describe '#order_by_name_asc' do
    # rubocop:disable RSpec/VariableName
    let!(:board_B) { create(:board, project: project, name: 'B') }
    let!(:board_C) { create(:board, project: project, name: 'C') }
    let!(:board_a) { create(:board, project: project, name: 'a') }
    let!(:board_A) { create(:board, project: project, name: 'A') }
    # rubocop:enable RSpec/VariableName

    it 'returns in case-insensitive alphabetical order and then by ascending id' do
      expect(project.boards.order_by_name_asc).to eq [board_a, board_A, board_B, board_C]
    end
  end

  describe '#first_board' do
    # rubocop:disable RSpec/VariableName
    let!(:board_B) { create(:board, project: project, name: 'B') }
    let!(:board_C) { create(:board, project: project, name: 'C') }
    let!(:board_a) { create(:board, project: project, name: 'a') }
    let!(:board_A) { create(:board, project: project, name: 'A') }
    # rubocop:enable RSpec/VariableName

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
