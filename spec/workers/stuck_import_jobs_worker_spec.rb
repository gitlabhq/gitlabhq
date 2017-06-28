require 'spec_helper'

describe StuckImportJobsWorker do
  let(:worker) { described_class.new }
  let(:exclusive_lease_uuid) { SecureRandom.uuid }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(exclusive_lease_uuid)
  end

  describe 'long running import' do
    let(:project) { create(:empty_project, import_jid: '123', import_status: 'started') }

    before do
      allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(['123'])
    end

    it 'marks the project as failed' do
      expect { worker.perform }.to change { project.reload.import_status }.to('failed')
    end
  end

  describe 'running import' do
    let(:project) { create(:empty_project, import_jid: '123', import_status: 'started') }

    before do
      allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])
    end

    it 'does not mark the project as failed' do
      worker.perform

      expect(project.reload.import_status).to eq('started')
    end
  end
end
