# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::ListsController do
  describe '#index' do
    let(:board) { create(:board) }
    let(:user) { board.project.owner }

    it 'does not have N+1 queries' do
      login_as(user)

      # First request has more queries because we create the default `backlog` list
      get board_lists_path(board)

      create(:list, board: board)

      control_count = ActiveRecord::QueryRecorder.new { get board_lists_path(board) }.count

      create_list(:list, 5, board: board)

      expect { get board_lists_path(board) }.not_to exceed_query_limit(control_count)
    end
  end
end
