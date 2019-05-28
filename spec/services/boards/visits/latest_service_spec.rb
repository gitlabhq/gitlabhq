# frozen_string_literal: true

require 'spec_helper'

describe Boards::Visits::LatestService do
  describe '#execute' do
    let(:user) { create(:user) }

    context 'when a project board' do
      let(:project)       { create(:project) }
      let(:project_board) { create(:board, project: project) }

      subject(:service) { described_class.new(project_board.parent, user) }

      it 'returns nil when there is no user' do
        service.current_user = nil

        expect(service.execute).to eq nil
      end

      it 'queries for most recent visit' do
        expect(BoardProjectRecentVisit).to receive(:latest).once

        service.execute
      end

      it 'queries for last N visits' do
        expect(BoardProjectRecentVisit).to receive(:latest).with(user, project, count: 5).once

        described_class.new(project_board.parent, user, count: 5).execute
      end
    end

    context 'when a group board' do
      let(:group)       { create(:group) }
      let(:group_board) { create(:board, group: group) }

      subject(:service) { described_class.new(group_board.parent, user) }

      it 'returns nil when there is no user' do
        service.current_user = nil

        expect(service.execute).to eq nil
      end

      it 'queries for most recent visit' do
        expect(BoardGroupRecentVisit).to receive(:latest).once

        service.execute
      end

      it 'queries for last N visits' do
        expect(BoardGroupRecentVisit).to receive(:latest).with(user, group, count: 5).once

        described_class.new(group_board.parent, user, count: 5).execute
      end
    end
  end
end
