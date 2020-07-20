# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::UpdateService do
  let(:user) { create(:user) }
  let!(:list) { create(:list, board: board, position: 0) }

  shared_examples 'moving list' do
    context 'when user can admin list' do
      it 'calls Lists::MoveService to update list position' do
        board.resource_parent.add_developer(user)

        expect(Boards::Lists::MoveService).to receive(:new).with(board.resource_parent, user, params).and_call_original
        expect_any_instance_of(Boards::Lists::MoveService).to receive(:execute).with(list)

        service.execute(list)
      end
    end

    context 'when user cannot admin list' do
      it 'does not call Lists::MoveService to update list position' do
        expect(Boards::Lists::MoveService).not_to receive(:new)

        service.execute(list)
      end
    end
  end

  shared_examples 'updating list preferences' do
    context 'when user can read list' do
      it 'updates list preference for user' do
        board.resource_parent.add_guest(user)

        service.execute(list)

        expect(list.preferences_for(user).collapsed).to eq(true)
      end
    end

    context 'when user cannot read list' do
      it 'does not update list preference for user' do
        service.execute(list)

        expect(list.preferences_for(user).collapsed).to be_nil
      end
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(board.resource_parent, user, params) }

    context 'when position parameter is present' do
      let(:params) { { position: 1 } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'moving list'
      end

      context 'for groups' do
        let(:group) { create(:group, :private) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'moving list'
      end
    end

    context 'when collapsed parameter is present' do
      let(:params) { { collapsed: true } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'updating list preferences'
      end

      context 'for groups' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'updating list preferences'
      end
    end

    context 'when position and collapsed are both present' do
      let(:params) { { collapsed: true, position: 1 } }

      context 'for projects' do
        let(:project) { create(:project, :private) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'moving list'
        it_behaves_like 'updating list preferences'
      end

      context 'for groups' do
        let(:group) { create(:group, :private) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'moving list'
        it_behaves_like 'updating list preferences'
      end
    end
  end
end
