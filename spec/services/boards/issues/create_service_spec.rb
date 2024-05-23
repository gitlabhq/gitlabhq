# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Issues::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }
    let!(:list)   { create(:list, board: board, label: label, position: 0) }

    subject(:service) { described_class.new(board.resource_parent, project, user, board_id: board.id, list_id: list.id, title: 'New issue') }

    before do
      project.add_developer(user)
    end

    it 'delegates the create proceedings to Issues::CreateService' do
      expect_next_instance_of(Issues::CreateService) do |instance|
        expect(instance).to receive(:execute).once
      end

      service.execute
    end

    it 'creates a new issue' do
      expect { service.execute }.to change(project.issues, :count).by(1)
    end

    it 'adds the label of the list to the issue' do
      result = service.execute

      expect(result).to be_success
      expect(result[:issue].labels).to contain_exactly(label)
    end
  end
end
