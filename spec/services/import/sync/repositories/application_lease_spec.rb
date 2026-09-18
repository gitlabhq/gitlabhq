# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Sync::Repositories::ApplicationLease, :clean_gitlab_redis_shared_state,
  feature_category: :importers do
  include ExclusiveLeaseHelpers

  let(:repository_id) { 123 }

  describe '.key' do
    it 'builds one stable application-fence key for a repository' do
      expect(described_class.key(repository_id)).to eq('import_sync:repository:123:application')
    end
  end

  describe '#execute' do
    subject(:lease) { described_class.new(repository_id) }

    context 'when the lease is obtained' do
      before do
        exclusive_lease = stub_exclusive_lease(described_class.key(repository_id))
        allow(exclusive_lease).to receive(:same_uuid?).and_return(true)
      end

      it 'yields a context and returns the block result' do
        result = lease.execute { |context| context.is_a?(described_class::Context) }

        expect(result).to be(true)
      end
    end

    context 'when the lease is already held' do
      subject(:lease) { described_class.new(repository_id, retries: 1, sleep_sec: 0) }

      before do
        stub_exclusive_lease_taken(described_class.key(repository_id))
      end

      it 'raises FailedToObtainLockError after the configured retries without running the block' do
        expect { lease.execute { raise 'block ran' } }
          .to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end

    context 'when the lease is lost mid-block' do
      let(:sleeping_lock) do
        instance_double(Gitlab::ExclusiveLeaseHelpers::SleepingLock, renew: false, same_uuid?: false)
      end

      before do
        allow(lease).to receive(:in_lock).and_yield(false, sleeping_lock)
      end

      it 'raises LostLeaseError from verify! after the block returns' do
        expect { lease.execute { true } }
          .to raise_error(described_class::LostLeaseError, /lease was lost/)
      end
    end

    context 'when the lease is renewed and still held' do
      let(:sleeping_lock) do
        instance_double(Gitlab::ExclusiveLeaseHelpers::SleepingLock, renew: true, same_uuid?: true)
      end

      before do
        allow(lease).to receive(:in_lock).and_yield(false, sleeping_lock)
      end

      it 'lets renew! succeed and a later verify! still pass' do
        result = lease.execute do |context|
          context.renew!
          context.verify!
        end

        expect(result).to be(true)
      end
    end
  end

  describe Import::Sync::Repositories::ApplicationLease::Context do
    let(:sleeping_lock) { instance_double(Gitlab::ExclusiveLeaseHelpers::SleepingLock) }

    subject(:context) { described_class.new(sleeping_lock, repository_id) }

    describe '#verify!' do
      it 'returns true when the lease uuid still matches' do
        allow(sleeping_lock).to receive(:same_uuid?).and_return(true)

        expect(context.verify!).to be(true)
      end

      it 'raises LostLeaseError when the lease uuid no longer matches' do
        allow(sleeping_lock).to receive(:same_uuid?).and_return(false)

        expect { context.verify! }
          .to raise_error(Import::Sync::Repositories::ApplicationLease::LostLeaseError, /lease was lost/)
      end
    end

    describe '#verify_repository!' do
      it 'returns true when the lease is held and the repository matches' do
        allow(sleeping_lock).to receive(:same_uuid?).and_return(true)

        expect(context.verify_repository!(repository_id)).to be(true)
      end

      it 'raises LostLeaseError when the lease uuid no longer matches' do
        allow(sleeping_lock).to receive(:same_uuid?).and_return(false)

        expect { context.verify_repository!(repository_id) }
          .to raise_error(Import::Sync::Repositories::ApplicationLease::LostLeaseError, /lease was lost/)
      end

      it 'raises LostLeaseError when the repository does not match' do
        allow(sleeping_lock).to receive(:same_uuid?).and_return(true)

        expect { context.verify_repository!(repository_id + 1) }
          .to raise_error(
            Import::Sync::Repositories::ApplicationLease::LostLeaseError, /does not match the repository/
          )
      end
    end

    describe '#renew!' do
      it 'returns true when the lease is renewed' do
        allow(sleeping_lock).to receive(:renew).and_return(true)

        expect(context.renew!).to be(true)
      end

      it 'raises LostLeaseError when the lease can no longer be renewed' do
        allow(sleeping_lock).to receive(:renew).and_return(false)

        expect { context.renew! }
          .to raise_error(Import::Sync::Repositories::ApplicationLease::LostLeaseError, /lease was lost/)
      end
    end
  end
end
