require 'spec_helper'

describe Issues::MoveService, services: true do
  let(:user) { create(:user) }
  let(:issue) { create(:issue, title: 'Some issue', description: 'Some issue description') }
  let(:current_project) { issue.project }
  let(:new_project) { create(:project) }

  before do
    current_project.team << [user, :master]
  end

  describe '#execute' do
    let!(:new_issue) do
      described_class.new(current_project, user).execute(issue, new_project)
    end

    it 'should create a new issue in a new project' do
      expect(new_issue.project).to eq new_project
    end

    it 'should add system note to old issue' do
      expect(issue.notes.last.note).to match /This issue has been moved to/
    end
  end
end
