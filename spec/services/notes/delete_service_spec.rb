require 'spec_helper'

describe Notes::DeleteService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:note) { create(:note, project: project, noteable: issue) }

  describe '#execute' do
    it 'deletes a note' do
      project = note.project
      described_class.new(project, note.author).execute(note)

      expect(project.issues.find(issue.id).notes).not_to include(note)
    end
  end
end
