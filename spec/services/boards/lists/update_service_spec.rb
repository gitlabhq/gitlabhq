# frozen_string_literal: true

require 'spec_helper'

describe Boards::Lists::UpdateService do
  let(:user) { create(:user) }
  let!(:list) { create(:list, board: board, position: 0) }

  shared_examples 'moving list' do
    context 'when user can admin list' do
      it 'calls Lists::MoveService to update list position' do
        board.parent.add_developer(user)
        service = described_class.new(board.parent, user, position: 1)

        expect(Boards::Lists::MoveService).to receive(:new).with(board.parent, user, { position: 1 }).and_call_original
        expect_any_instance_of(Boards::Lists::MoveService).to receive(:execute).with(list)

        service.execute(list)
      end
    end

    context 'when user cannot admin list' do
      it 'does not call Lists::MoveService to update list position' do
        service = described_class.new(board.parent, user, position: 1)

        expect(Boards::Lists::MoveService).not_to receive(:new)

        service.execute(list)
      end
    end
  end

  shared_examples 'updating list preferences' do
    context 'when user can read list' do
      it 'updates list preference for user' do
        board.parent.add_guest(user)
        service = described_class.new(board.parent, user, collapsed: true)

        service.execute(list)

        expect(list.preferences_for(user).collapsed).to eq(true)
      end
    end

    context 'when user cannot read list' do
      it 'does not update list preference for user' do
        service = described_class.new(board.parent, user, collapsed: true)

        service.execute(list)

        expect(list.preferences_for(user).collapsed).to be_nil
      end
    end
  end

  describe '#execute' do
    context 'when position parameter is present' do
      context 'for projects' do
        it_behaves_like 'moving list' do
          let(:project) { create(:project, :private) }
          let(:board) { create(:board, project: project) }
        end
      end

      context 'for groups' do
        it_behaves_like 'moving list' do
          let(:group) { create(:group, :private) }
          let(:board) { create(:board, group: group) }
        end
      end
    end

    context 'when collapsed parameter is present' do
      context 'for projects' do
        it_behaves_like 'updating list preferences' do
          let(:project) { create(:project, :private) }
          let(:board) { create(:board, project: project) }
        end
      end

      context 'for groups' do
        it_behaves_like 'updating list preferences' do
          let(:group) { create(:group, :private) }
          let(:board) { create(:board, group: group) }
        end
      end
    end
  end
end
