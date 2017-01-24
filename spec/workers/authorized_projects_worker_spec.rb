require 'spec_helper'

describe AuthorizedProjectsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it "refreshes user's authorized projects" do
      user = create(:user)

      expect_any_instance_of(User).to receive(:refresh_authorized_projects)

      worker.perform(user.id)
    end

    context "when the user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        described_class.new.perform(-1)
      end
    end
  end
end
