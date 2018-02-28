require 'spec_helper'

describe StuckImportJobsWorker do
  let(:worker) { described_class.new }
  let(:exclusive_lease_uuid) { SecureRandom.uuid }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(exclusive_lease_uuid)
  end

  describe 'with started import_status' do
    let(:project) { create(:project, :import_started, import_jid: '123') }

    describe 'long running import' do
      it 'marks the project as failed' do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(['123'])

        expect { worker.perform }.to change { project.reload.import_status }.to('failed')
      end
    end

    describe 'running import' do
      it 'does not mark the project as failed' do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])

        expect { worker.perform }.not_to change { project.reload.import_status }
      end

      describe 'import without import_jid' do
        it 'marks the project as failed' do
          expect { worker.perform }.to change { project.reload.import_status }.to('failed')
        end
      end
    end
  end
end
