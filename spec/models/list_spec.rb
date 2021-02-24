# frozen_string_literal: true

require 'spec_helper'

RSpec.describe List do
  it_behaves_like 'having unique enum values'
  it_behaves_like 'boards listable model', :list
  it_behaves_like 'list_preferences_for user', :list, :list_id

  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }
  end

  describe '.without_types' do
    it 'exclude lists of given types' do
      board = create(:list, list_type: :label).board
      # closed list is created by default
      backlog_list = create(:list, list_type: :backlog, board: board)

      exclude_type = [described_class.list_types[:label], described_class.list_types[:closed]]

      lists = described_class.without_types(exclude_type)
      expect(lists.where(board: board)).to match_array([backlog_list])
    end
  end
end
