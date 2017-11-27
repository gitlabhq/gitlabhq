require 'spec_helper'

describe StuckCiJobsWorker do
  let!(:runner) { create :ci_runner }
  let!(:job) { create :ci_build, runner: runner }
  let(:worker) { described_class.new }
  let(:exclusive_lease_uuid) { SecureRandom.uuid }

  before do
    job.update!(status: status, updated_at: updated_at)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(exclusive_lease_uuid)
  end

  shared_examples 'job is dropped' do
    before do
      worker.perform
      job.reload
    end

    it "changes status" do
      expect(job).to be_failed
      expect(job).to be_stuck_or_timeout_failure
    end
  end

  shared_examples 'job is unchanged' do
    before do
      worker.perform
      job.reload
    end

    it "doesn't change status" do
      expect(job.status).to eq(status)
    end
  end

  context 'when job is pending' do
    let(:status) { 'pending' }

    context 'when job is not stuck' do
      before do
        allow_any_instance_of(Ci::Build).to receive(:stuck?).and_return(false)
      end

      context 'when job was not updated for more than 1 day ago' do
        let(:updated_at) { 2.days.ago }
        it_behaves_like 'job is dropped'
      end

      context 'when job was updated in less than 1 day ago' do
        let(:updated_at) { 6.hours.ago }
        it_behaves_like 'job is unchanged'
      end

      context 'when job was not updated for more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }
        it_behaves_like 'job is unchanged'
      end
    end

    context 'when job is stuck' do
      before do
        allow_any_instance_of(Ci::Build).to receive(:stuck?).and_return(true)
      end

      context 'when job was not updated for more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }
        it_behaves_like 'job is dropped'
      end

      context 'when job was updated in less than 1 hour ago' do
        let(:updated_at) { 30.minutes.ago }
        it_behaves_like 'job is unchanged'
      end
    end
  end

  context 'when job is running' do
    let(:status) { 'running' }

    context 'when job was not updated for more than 1 hour ago' do
      let(:updated_at) { 2.hours.ago }
      it_behaves_like 'job is dropped'
    end

    context 'when job was updated in less than 1 hour ago' do
      let(:updated_at) { 30.minutes.ago }
      it_behaves_like 'job is unchanged'
    end
  end

  %w(success skipped failed canceled).each do |status|
    context "when job is #{status}" do
      let(:status) { status }
      let(:updated_at) { 2.days.ago }
      it_behaves_like 'job is unchanged'
    end
  end

  context 'for deleted project' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }

    before do
      job.project.update(pending_delete: true)
    end

    it 'does drop job' do
      expect_any_instance_of(Ci::Build).to receive(:drop).and_call_original
      worker.perform
    end
  end

  describe 'exclusive lease' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }
    let(:worker2) { described_class.new }

    it 'is guard by exclusive lease when executed concurrently' do
      expect(worker).to receive(:drop).at_least(:once).and_call_original
      expect(worker2).not_to receive(:drop)
      worker.perform
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)
      worker2.perform
    end

    it 'can be executed in sequence' do
      expect(worker).to receive(:drop).at_least(:once).and_call_original
      expect(worker2).to receive(:drop).at_least(:once).and_call_original
      worker.perform
      worker2.perform
    end

    it 'cancels exclusive lease after worker perform' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).with(described_class::EXCLUSIVE_LEASE_KEY, exclusive_lease_uuid)
      worker.perform
    end
  end
end
