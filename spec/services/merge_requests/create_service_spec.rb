require 'spec_helper'

describe MergeRequests::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe :execute do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'stable',
          target_branch: 'master'
        }

        @merge_request = MergeRequests::CreateService.new(project, user, opts).execute
      end

      it { @merge_request.should be_valid }
      it { @merge_request.title.should == 'Awesome merge_request' }
    end
  end
end
