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

        @note = Notes::CreateService.new(project, user, opts).execute
      end

      it { @note.should be_valid }
      it { @note.note.should == 'Awesome comment' }
    end
  end
end

