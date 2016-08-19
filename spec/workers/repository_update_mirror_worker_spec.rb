require 'rails_helper'

describe RepositoryUpdateMirrorWorker do
  describe '#perform' do
    it 'sets import as finished when update mirror service executes successfully' do
      project = create(:empty_project, :mirror)

      expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)

      expect { described_class.new.perform(project.id) }
        .to change { project.reload.import_status }.to('finished')
    end

    it 'sets import as failed when update mirror service executes with errors' do
      project = create(:empty_project, :mirror)

      expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :error, message: 'fail!')

      expect { described_class.new.perform(project.id) }
        .to change { project.reload.import_status }.to('failed')
    end
  end
end
