# frozen_string_literal: true

require 'spec_helper'

describe Board do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#order_by_name_asc' do
    let!(:second_board) { create(:board, name: 'Secondary board', project: project) }
    let!(:first_board)  { create(:board, name: 'First board', project: project) }

    it 'returns in alphabetical order' do
      expect(project.boards.order_by_name_asc).to eq [first_board, second_board]
    end
  end

  describe '#first_board' do
    let!(:other_board)  { create(:board, name: 'Other board', project: other_project) }
    let!(:second_board) { create(:board, name: 'Secondary board', project: project) }
    let!(:first_board)  { create(:board, name: 'First board', project: project) }

    it 'return the first alphabetical board as a relation' do
      expect(project.boards.first_board).to eq [first_board]
    end

    # BoardsActions#board expects this behavior
    it 'raises an error when find is done on a non-existent record' do
      expect { project.boards.first_board.find(second_board.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
