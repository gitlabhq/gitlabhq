require 'spec_helper'

describe Boards::CreateService do
  describe '#execute' do
    let(:project) { create(:empty_project) }

    context 'With the feature available' do
      before do
        stub_licensed_features(multiple_issue_boards: true)
      end

      context 'with valid params' do
        subject(:service) { described_class.new(project, double, name: 'Backend') }

        it 'creates a new project board' do
          expect { service.execute }.to change(project.boards, :count).by(1)
        end

        it 'creates the default lists' do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.first).to be_backlog
          expect(board.lists.last).to be_closed
        end
      end

      context 'with invalid params' do
        subject(:service) { described_class.new(project, double, name: nil) }

        it 'does not create a new project board' do
          expect { service.execute }.not_to change(project.boards, :count)
        end

        it "does not create board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 0
        end
      end

      context 'without params' do
        subject(:service) { described_class.new(project, double) }

        it 'creates a new project board' do
          expect { service.execute }.to change(project.boards, :count).by(1)
        end

        it "creates board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.last).to be_closed
        end
      end
    end

    it 'skips creating a second board when the feature is not available' do
      stub_licensed_features(multiple_issue_boards: false)
      service = described_class.new(project, double)

      expect(service.execute).not_to be_nil

      expect { service.execute }.not_to change(project.boards, :count)
    end
  end
end
