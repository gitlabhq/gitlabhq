# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardProjectRecentVisit do
  let_it_be(:board_parent) { create(:project) }
  let_it_be(:board) { create(:board, project: board_parent) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:board) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:board) }
  end

  it_behaves_like 'boards recent visit' do
    let_it_be(:board_relation) { :board }
    let_it_be(:board_parent_relation) { :project }
    let_it_be(:visit_relation) { :board_project_recent_visit }
  end
end
