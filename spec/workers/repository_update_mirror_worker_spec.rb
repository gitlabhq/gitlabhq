require 'rails_helper'

describe RepositoryUpdateMirrorWorker do
  subject { described_class.new }

  describe '#perform' do
    context 'with status none' do
      let(:project) { create(:project, :mirror, :import_scheduled) }

      it 'sets status as finished when update mirror service executes successfully' do
        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)

        expect { subject.perform(project.id) }.to change { project.reload.import_status }.to('finished')
      end

      it 'sets status as failed when update mirror service executes with errors' do
        error_message = 'fail!'

        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :error, message: error_message)

        expect do
          subject.perform(project.id)
        end.to raise_error(RepositoryUpdateMirrorWorker::UpdateError, error_message)
        expect(project.reload.import_status).to eq('failed')
      end
    end

    context 'with another worker already running' do
      it 'returns nil' do
        mirror = create(:project, :repository, :mirror, :import_started)

        expect(subject.perform(mirror.id)).to be nil
      end
    end

    context 'with unexpected error' do
      it 'marks mirror as failed' do
        mirror = create(:project, :repository, :mirror, :import_scheduled)

        allow_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_raise(RuntimeError)

        expect do
          subject.perform(mirror.id)
        end.to raise_error(RepositoryUpdateMirrorWorker::UpdateError)
        expect(mirror.reload.import_status).to eq('failed')
      end
    end

    context 'threshold_reached?' do
      let(:mirror) { create(:project, :repository, :mirror, :import_scheduled) }

      before do
        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)
      end

      context 'with threshold_reached? true' do
        it 'schedules UpdateAllMirrorsWorker' do
          expect(Gitlab::Mirror).to receive(:threshold_reached?).and_return(true)

          expect(UpdateAllMirrorsWorker).to receive(:perform_async)

          subject.perform(mirror.id)
        end
      end

      context 'with threshold_reached? false' do
        it 'does not schedule UpdateAllMirrorsWorker' do
          expect(Gitlab::Mirror).to receive(:threshold_reached?).and_return(false)

          expect(UpdateAllMirrorsWorker).not_to receive(:perform_async)

          subject.perform(mirror.id)
        end
      end
    end
  end
end
