require 'rails_helper'

describe RepositoryUpdateRemoteMirrorWorker do
  subject { described_class.new }

  let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }
  let(:scheduled_time) { Time.now - 5.minutes }

  around do |example|
    Timecop.freeze(Time.now) { example.run }
  end

  describe '#perform' do
    context 'with status none' do
      before do
        remote_mirror.update(update_status: 'none')
      end

      it 'sets status as finished when update remote mirror service executes successfully' do
        expect_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_return(status: :success)

        expect { subject.perform(remote_mirror.id, Time.now) }.to change { remote_mirror.reload.update_status }.to('finished')
      end

      it 'sets status as failed when update remote mirror service executes with errors' do
        error_message = 'fail!'

        expect_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_return(status: :error, message: error_message)
        expect do
          subject.perform(remote_mirror.id, Time.now)
        end.to raise_error(RepositoryUpdateRemoteMirrorWorker::UpdateError, error_message)

        expect(remote_mirror.reload.update_status).to eq('failed')
      end

      it 'does nothing if last_update_started_at is higher than the time the job was scheduled in' do
        remote_mirror.update(last_update_started_at: Time.now)

        expect_any_instance_of(RemoteMirror).to receive(:updated_since?).with(scheduled_time).and_return(true)
        expect_any_instance_of(Projects::UpdateRemoteMirrorService).not_to receive(:execute).with(remote_mirror)

        expect(subject.perform(remote_mirror.id, scheduled_time)).to be_nil
      end
    end

    context 'with unexpected error' do
      it 'marks mirror as failed' do
        allow_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_raise(RuntimeError)

        expect do
          subject.perform(remote_mirror.id, Time.now)
        end.to raise_error(RepositoryUpdateRemoteMirrorWorker::UpdateError)
        expect(remote_mirror.reload.update_status).to eq('failed')
      end
    end

    context 'with another worker already running' do
      before do
        remote_mirror.update(update_status: 'started')
      end

      it 'raises RemoteMirrorUpdateAlreadyInProgressError' do
        expect do
          subject.perform(remote_mirror.id, Time.now)
        end.to raise_error(RepositoryUpdateRemoteMirrorWorker::UpdateAlreadyInProgressError)
      end
    end

    context 'with status failed' do
      before do
        remote_mirror.update(update_status: 'failed')
      end

      it 'sets status as finished if last_update_started_at is higher than the time the job was scheduled in' do
        remote_mirror.update(last_update_started_at: Time.now)

        expect_any_instance_of(RemoteMirror).to receive(:updated_since?).with(scheduled_time).and_return(false)
        expect_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_return(status: :success)

        expect { subject.perform(remote_mirror.id, scheduled_time) }.to change { remote_mirror.reload.update_status }.to('finished')
      end
    end
  end
end
