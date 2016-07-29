require 'rails_helper'

describe RepositoryUpdateMirrorWorker do
  describe '#perform' do
    it "just returns if cannot obtain a lease" do
      worker = described_class.new
      project_id = 15

      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(false)

      expect(Projects::UpdateMirrorService).not_to receive(:execute)

      worker.perform(project_id)
    end

    context "when obtain the lease" do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease)
          .to receive(:try_obtain).and_return(true)
      end

      it "sets import as finished when update mirror service executes successfully" do
        project = create(:empty_project, :mirror)

        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)

        expect do
          described_class.new.perform(project.id)
        end.to change { project.reload.import_status }.to("finished")
      end

      it "sets import as failed when update mirror service executes with errors" do
        project = create(:empty_project, :mirror)

        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :error, message: 'fail!')

        expect do
          described_class.new.perform(project.id)
        end.to change { project.reload.import_status }.to("failed")
      end
    end
  end
end
