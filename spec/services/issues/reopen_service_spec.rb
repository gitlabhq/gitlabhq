require 'spec_helper'

describe Issues::ReopenService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, :closed, project: project) }

  describe '#execute' do
    context 'current user is not authorized to reopen issue' do
      before do
        guest = create(:user)
        project.team << [guest, :guest]

        perform_enqueued_jobs do
          described_class.new(project, guest).execute(issue)
        end
      end

      it 'does not reopen the issue' do
        expect(issue).to be_closed
      end
    end

    context 'when issue is confidential' do
      it 'does not execute hooks' do
        user = create(:user)
        project.team << [user, :master]

        issue = create(:issue, :confidential, :closed, project: project)

        expect(project).not_to receive(:execute_hooks)
        expect(project).not_to receive(:execute_services)

        described_class.new(project, user).execute(issue)
      end
    end
  end
end
