require 'spec_helper'

describe Milestones::UpdateService do
  let(:project) { create(:project) }
  let(:user) { build(:user) }
  let(:milestone) { create(:milestone, project: project) }

  describe '#execute' do
    context "valid params" do
      before do
        project.add_maintainer(user)

        @milestone = described_class.new(project, user, { title: 'new_title' }).execute(milestone)
      end

      it { expect(@milestone).to be_valid }
      it { expect(@milestone.title).to eq('new_title') }
    end
  end
end
