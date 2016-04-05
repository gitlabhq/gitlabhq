require 'spec_helper'

describe Notes::DeleteService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }
  let(:note) { create(:note, project: project, noteable: issue, author: user, note: 'Note') }

  describe '#execute' do
    it 'deletes a note' do
      Notes::DeleteService.new(project, user).execute(note)
      expect(project.issues.find(issue.id).notes).to_not include(note)
    end
  end
end
