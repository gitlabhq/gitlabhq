require 'rails_helper'

describe RepositoryUpdateRemoteMirrorWorker do
  subject { described_class.new }

  let(:remote_mirror) { create(:project, :remote_mirror).remote_mirrors.first }

  before do
    remote_mirror.update_attributes(update_status: 'started')
  end

  describe '#perform' do
    it 'sets sync as finished when update remote mirror service executes successfully' do
      expect_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_return(status: :success)

      expect { subject.perform(remote_mirror.id, Time.now) }.to change { remote_mirror.reload.update_status }.to('finished')
    end

    it 'sets sync as failed when update remote mirror service executes with errors' do
      expect_any_instance_of(Projects::UpdateRemoteMirrorService).to receive(:execute).with(remote_mirror).and_return(status: :error, message: 'fail!')

      expect { subject.perform(remote_mirror.id, Time.now) }.to change { remote_mirror.reload.update_status }.to('failed')
    end

    it 'does nothing if last_update_at is higher than the time the job was scheduled in' do
      expect_any_instance_of(RemoteMirror).to receive(:last_update_at).and_return(Time.now + 10.minutes)
      expect_any_instance_of(Projects::UpdateRemoteMirrorService).not_to receive(:execute).with(remote_mirror)

      expect(subject.perform(remote_mirror.id, Time.now)).to be_nil
    end
  end
end
