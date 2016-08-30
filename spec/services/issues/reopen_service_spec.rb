require 'spec_helper'

describe Issues::ReopenService, services: true do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, :closed, project: project) }

  describe '#execute' do
    context 'when user is not authorized to reopen issue' do
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

    context 'when user is authrized to reopen issue' do
      let(:user) { create(:user) }

      before do
        project.team << [user, :master]
      end

      context 'when issue is not confidential' do
        it 'executes issue hooks' do
          expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
          expect(project).to receive(:execute_services).with(an_instance_of(Hash), :issue_hooks)

          described_class.new(project, user).execute(issue)
        end
      end

      context 'when issue is confidential' do
        it 'executes confidential issue hooks' do
          issue = create(:issue, :confidential, :closed, project: project)

          expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
          expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

          described_class.new(project, user).execute(issue)
        end
      end
    end
  end
end
