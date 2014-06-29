require 'spec_helper'

describe Issues::CreateService do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  describe :execute do
    context "valid params" do
      before do
        project.team << [user, :master]
        opts = {
          title: 'Awesome issue',
          description: 'please fix'
        }

        @issue = Issues::CreateService.new(project, user, opts).execute
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue.title).to eq('Awesome issue') }
    end
  end
end
