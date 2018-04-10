require 'spec_helper'

describe Milestones::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe '#execute' do
    context "valid params" do
      before do
        project.add_master(user)

        opts = {
          title: 'v2.1.9',
          description: 'Patch release to fix security issue'
        }

        @milestone = described_class.new(project, user, opts).execute
      end

      it { expect(@milestone).to be_valid }
      it { expect(@milestone.title).to eq('v2.1.9') }
    end
  end
end
