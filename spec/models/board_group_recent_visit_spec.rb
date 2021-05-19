# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardGroupRecentVisit do
  let_it_be(:board_parent) { create(:group) }
  let_it_be(:board) { create(:board, group: board_parent) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:board) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:board) }
  end

  it_behaves_like 'boards recent visit' do
    let_it_be(:board_relation) { :board }
    let_it_be(:board_parent_relation) { :group }
    let_it_be(:visit_relation) { :board_group_recent_visit }
  end
end
