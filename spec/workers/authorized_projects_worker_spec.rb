require 'spec_helper'

describe AuthorizedProjectsWorker do
  describe '#perform' do
    let(:user) { create(:user) }

    subject(:job) { described_class.new }

    it "refreshes user's authorized projects" do
      expect_any_instance_of(User).to receive(:refresh_authorized_projects)

      job.perform(user.id)
    end

    context "when the user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        job.perform(-1)
      end
    end
  end
end
