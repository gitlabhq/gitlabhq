require 'spec_helper'

describe AuthorizedProjectsWorker do
  let(:worker) { described_class.new }

  describe '.bulk_perform_and_wait' do
    it 'schedules the ids and waits for the jobs to complete' do
      project = create(:project)

      project.owner.project_authorizations.delete_all

      described_class.bulk_perform_and_wait([[project.owner.id]])

      expect(project.owner.project_authorizations.count).to eq(1)
    end
  end

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
