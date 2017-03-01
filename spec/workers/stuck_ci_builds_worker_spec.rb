require 'spec_helper'

describe StuckCiBuildsWorker do
  let!(:runner) { create :ci_runner }
  let!(:build) { create :ci_build, runner: runner }
  let(:worker) { described_class.new }
  let(:exclusive_lease_uuid) { SecureRandom.uuid }

  subject do
    build.reload
    build.status
  end

  before do
    build.update!(status: status, updated_at: updated_at)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(exclusive_lease_uuid)
  end

  shared_examples 'build is dropped' do
    it 'changes status' do
      worker.perform
      is_expected.to eq('failed')
    end
  end

  shared_examples 'build is unchanged' do
    it "doesn't change status" do
      worker.perform
      is_expected.to eq(status)
    end
  end

  context 'when build is pending' do
    let(:status) { 'pending' }

    context 'when build is not stuck' do
      before { allow_any_instance_of(Ci::Build).to receive(:stuck?).and_return(false) }

      context 'when build was not updated for more than 1 day ago' do
        let(:updated_at) { 2.days.ago }
        it_behaves_like 'build is dropped'
      end

      context 'when build was updated in less than 1 day ago' do
        let(:updated_at) { 6.hours.ago }
        it_behaves_like 'build is unchanged'
      end

      context 'when build was not updated for more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }
        it_behaves_like 'build is unchanged'
      end
    end

    context 'when build is stuck' do
      before { allow_any_instance_of(Ci::Build).to receive(:stuck?).and_return(true) }

      context 'when build was not updated for more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }
        it_behaves_like 'build is dropped'
      end

      context 'when build was updated in less than 1 hour ago' do
        let(:updated_at) { 30.minutes.ago }
        it_behaves_like 'build is unchanged'
      end
    end
  end

  context 'when build is running' do
    let(:status) { 'running' }

    context 'when build was not updated for more than 1 hour ago' do
      let(:updated_at) { 2.hours.ago }
      it_behaves_like 'build is dropped'
    end

    context 'when build was updated in less than 1 hour ago' do
      let(:updated_at) { 30.minutes.ago }
      it_behaves_like 'build is unchanged'
    end
  end

  %w(success skipped failed canceled).each do |status|
    context "when build is #{status}" do
      let(:status) { status }
      let(:updated_at) { 2.days.ago }
      it_behaves_like 'build is unchanged'
    end
  end

  context 'for deleted project' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }

    before { build.project.update(pending_delete: true) }

    it 'does not drop build' do
      expect_any_instance_of(Ci::Build).not_to receive(:drop)
      worker.perform
    end
  end

  describe 'exclusive lease' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }
    let(:worker2) { described_class.new }

    it 'is guard by exclusive lease when executed concurrently' do
      expect(worker).to receive(:drop).at_least(:once)
      expect(worker2).not_to receive(:drop)
      worker.perform
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)
      worker2.perform
    end

    it 'can be executed in sequence' do
      expect(worker).to receive(:drop).at_least(:once)
      expect(worker2).to receive(:drop).at_least(:once)
      worker.perform
      worker2.perform
    end

    it 'cancels exclusive lease after worker perform' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).with(described_class::EXCLUSIVE_LEASE_KEY, exclusive_lease_uuid)
      worker.perform
    end
  end
end
