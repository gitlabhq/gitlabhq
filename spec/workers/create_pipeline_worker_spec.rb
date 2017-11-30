require 'spec_helper'

describe CreatePipelineWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when a project not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect { worker.perform(99, create(:user).id, 'master', :web) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when a user not found' do
      let(:project) { create(:project) }

      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect { worker.perform(project.id, 99, project.default_branch, :web) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when everything is ok' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }

      it 'calls the Service' do
        expect(Ci::CreatePipelineService).to receive(:new).with(project, user, ref: project.default_branch).and_return(create_pipeline_service)
        expect(create_pipeline_service).to receive(:execute).with(:web, any_args)

        worker.perform(project.id, user.id, project.default_branch, :web)
      end
    end
  end
end
