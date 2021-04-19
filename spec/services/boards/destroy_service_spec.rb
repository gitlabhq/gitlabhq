# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::DestroyService do
  context 'with project board' do
    let_it_be(:parent) { create(:project) }

    let(:boards) { parent.boards }
    let(:board_factory) { :board }

    it_behaves_like 'board destroy service'
  end

  context 'with group board' do
    let_it_be(:parent) { create(:group) }

    let(:boards) { parent.boards }
    let(:board_factory) { :board }

    it_behaves_like 'board destroy service'
  end
end
