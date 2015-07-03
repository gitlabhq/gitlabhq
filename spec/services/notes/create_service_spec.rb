require 'spec_helper'

describe Notes::CreateService do
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe :execute do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          note: 'Awesome comment',
          noteable_type: 'Issue',
          noteable_id: issue.id
        }

        expect(project).to receive(:execute_hooks)
        expect(project).to receive(:execute_services)
        @note = Notes::CreateService.new(project, user, opts).execute
      end

      it { expect(@note).to be_valid }
      it { expect(@note.note).to eq('Awesome comment') }
    end
  end
end
