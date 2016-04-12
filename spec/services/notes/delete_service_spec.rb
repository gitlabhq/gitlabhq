require 'spec_helper'

describe Notes::DeleteService, services: true do
  describe '#execute' do
    it 'deletes a note' do
      project = create(:empty_project)
      issue = create(:issue, project: project)
      note = create(:note, project: project, noteable: issue)

      described_class.new(project, note.author).execute(note)

      expect(project.issues.find(issue.id).notes).not_to include(note)
    end
  end
end
