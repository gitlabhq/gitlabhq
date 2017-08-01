require 'spec_helper'

describe Boards::Lists::GenerateService, services: true do
  # describe '#execute' do
  #   let(:group) { create(:group) }
  #   let(:board)   { create(:board, group: group) }
  #   let(:user)    { create(:user) }

  #   subject(:service) { described_class.new(group, user) }

  #   before do
  #     group.add_developer(user)
  #   end

  #   context 'when board lists is empty' do
  #     it 'creates the default lists' do
  #       expect { service.execute(board) }.to change(board.lists, :count).by(2)
  #     end
  #   end

  #   context 'when board lists is not empty' do
  #     it 'does not creates the default lists' do
  #       create(:list, board: board)

  #       expect { service.execute(board) }.not_to change(board.lists, :count)
  #     end
  #   end

  #   context 'when group labels does not contains any list label' do
  #     it 'creates labels' do
  #       expect { service.execute(board) }.to change(group.labels, :count).by(2)
  #     end
  #   end

  #   context 'when group labels contains some of list label' do
  #     it 'creates the missing labels' do
  #       create(:group_label, group: group, name: 'Doing')

  #       expect { service.execute(board) }.to change(group.labels, :count).by(1)
  #     end
  #   end
  # end
end
