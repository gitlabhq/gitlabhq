require 'spec_helper'

describe Issues::UpdateService do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue) }

  describe :execute do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          title: 'New title',
          description: 'Also please fix'
        }

        @issue = Issues::UpdateService.new(project, user, opts).execute(issue)
      end

      it { @issue.should be_valid }
      it { @issue.title.should == 'New title' }
    end
  end
end
