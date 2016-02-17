require 'spec_helper'

describe Issues::MoveService, services: true do
  let(:user) { create(:user) }
  let(:issue) { create(:issue, title: 'Some issue', description: 'Some issue description') }
  let(:current_project) { issue.project }
  let(:new_project) { create(:project) }
  let(:move_params) { { 'move_to_project_id' => new_project.id } }
  let(:move_service) { described_class.new(current_project, user, move_params, issue) }

  before do
    current_project.team << [user, :master]
  end

  context 'issue movable' do
    describe '#move?' do
      subject { move_service.move? }
      it { is_expected.to be_truthy }
    end

    describe '#execute' do
      let!(:new_issue) { move_service.execute }

      it 'should create a new issue in a new project' do
        expect(new_issue.project).to eq new_project
      end

      it 'should add system note to old issue' do
        expect(issue.notes.last.note).to match /^Moved to/
      end

      it 'should add system note to new issue' do
        expect(new_issue.notes.last.note).to match /^Moved from/
      end
    end
  end

  context 'issue not movable' do
    context 'move not requested' do
      let(:move_params) { {} }

      describe '#move?' do
        subject { move_service.move? }
        it { is_expected.to be_falsey }
      end
    end
  end
end
