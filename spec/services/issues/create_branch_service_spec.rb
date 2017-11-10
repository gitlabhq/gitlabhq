require 'spec_helper'

describe Issues::CreateBranchService, services: true do
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when repository is empty' do
      let(:project) { create(:project, :repository) }
      let(:issue) { create(:issue, project: project) }

      it 'creates a branch if the branch name is valid and adds a system note' do
        result = service.execute(issue, 'my-issue-branch', 'master')

        expect(result[:status]).to eq(:success)
        expect(issue.notes.last.note).to include('created branch [`my-issue-branch`]')
      end

      it 'does not create a branch if branch name is invalid' do
        result = service.execute(issue, 'NOT valid name', 'master')

        expect(result[:status]).to eq(:error)
        expect(SystemNoteService).not_to receive(:new_issue_branch)
      end
    end
  end
end
