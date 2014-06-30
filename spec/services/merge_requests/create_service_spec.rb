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

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('Awesome merge_request') }
    end
  end
end
