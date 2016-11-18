require 'spec_helper'

describe AuthorizedProjectsWorker do
  describe '#perform' do
    it "refreshes user's authorized projects" do
      user = create(:user)

      expect(User).to receive(:find_by).with(id: user.id).and_return(user)
      expect(user).to receive(:refresh_authorized_projects)

      described_class.new.perform(user.id)
    end

    context "when user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        described_class.new.perform(999_999)
      end
    end
  end
end
