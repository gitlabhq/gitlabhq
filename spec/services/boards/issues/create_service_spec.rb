require 'spec_helper'

describe Boards::Issues::CreateService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }
    let!(:list)   { create(:list, board: board, label: label, position: 0) }

    subject(:service) { described_class.new(project, user, title: 'New issue') }

    before do
      project.team << [user, :developer]
    end

    it 'delegates the create proceedings to Issues::CreateService' do
      expect_any_instance_of(Issues::CreateService).to receive(:execute).once

      service.execute(list)
    end

    it 'creates a new issue' do
      expect { service.execute(list) }.to change(project.issues, :count).by(1)
    end

    it 'adds the label of the list to the issue' do
      issue = service.execute(list)

      expect(issue.labels).to eq [label]
    end
  end
end
