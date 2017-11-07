require 'spec_helper'

describe LfsProjectCleanupWorker do
  let!(:project) { create(:project) }

  it 'calls service to cleanup unreferenced LFS pointers' do
    expect_any_instance_of(LfsCleanupService).to receive(:execute)

    subject.perform(project.id)
  end

  describe '.perform_async_with_lease' do
    context "when it hasn't recently ran" do
      before do
        exclusive_lease_uuid = SecureRandom.uuid
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(exclusive_lease_uuid)
      end

      it "schedules the worker" do
        expect_any_instance_of(LfsCleanupService).to receive(:execute)

        described_class.perform_async_with_lease(project.id)
      end
    end

    context 'when it has already been recently ran' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)
      end

      it "doesn't run again" do
        expect_any_instance_of(LfsCleanupService).not_to receive(:execute)

        described_class.perform_async_with_lease(project.id)
      end
    end
  end
end
