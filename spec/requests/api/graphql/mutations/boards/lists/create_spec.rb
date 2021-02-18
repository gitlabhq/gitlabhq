# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a label or backlog board list' do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }

  it_behaves_like 'board lists create request' do
    let(:mutation_name) { :board_list_create }
  end
end
