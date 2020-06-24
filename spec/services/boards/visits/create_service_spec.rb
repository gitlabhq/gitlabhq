# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Visits::CreateService do
  describe '#execute' do
    let(:user) { create(:user) }

    context 'when a project board' do
      let(:project)       { create(:project) }
      let(:project_board) { create(:board, project: project) }

      subject(:service) { described_class.new(project_board.resource_parent, user) }

      it 'returns nil when there is no user' do
        service.current_user = nil

        expect(service.execute(project_board)).to eq nil
      end

      it 'returns nil when database is read only' do
        allow(Gitlab::Database).to receive(:read_only?) { true }

        expect(service.execute(project_board)).to eq nil
      end

      it 'records the visit' do
        expect(BoardProjectRecentVisit).to receive(:visited!).once

        service.execute(project_board)
      end
    end

    context 'when a group board' do
      let(:group)       { create(:group) }
      let(:group_board) { create(:board, group: group) }

      subject(:service) { described_class.new(group_board.resource_parent, user) }

      it 'returns nil when there is no user' do
        service.current_user = nil

        expect(service.execute(group_board)).to eq nil
      end

      it 'records the visit' do
        expect(BoardGroupRecentVisit).to receive(:visited!).once

        service.execute(group_board)
      end
    end
  end
end
