require 'spec_helper'

describe AuthorizedProjectsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it "refreshes user's authorized projects" do
      user = create(:user)

      expect(worker).to receive(:refresh).with(an_instance_of(User))

      worker.perform(user.id)
    end

    context "when the user is not found" do
      it "does nothing" do
        expect(worker).not_to receive(:refresh)

        described_class.new.perform(-1)
      end
    end
  end

  describe '#refresh', redis: true do
    it 'refreshes the authorized projects of the user' do
      user = create(:user)

      expect(user).to receive(:refresh_authorized_projects)

      worker.refresh(user)
    end
  end
end
