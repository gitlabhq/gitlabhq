# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExclusiveLeaseGuard, :clean_gitlab_redis_shared_state, feature_category: :shared do
  subject :subject_class do
    Class.new do
      include ExclusiveLeaseGuard

      def self.name
        'ExclusiveLeaseGuardTestClass'
      end

      def call(&block)
        try_obtain_lease do
          internal_method(&block)
        end
      end

      def internal_method
        yield
      end

      def lease_timeout
        1.second
      end
    end
  end

  describe '#try_obtain_lease' do
    let(:subject) { subject_class.new }

    it 'obtains the lease, calls internal_method and releases the lease', :aggregate_failures do
      expect(subject).to receive(:internal_method).and_call_original

      subject.call do
        expect(subject.exclusive_lease.exists?).to be_truthy
      end

      expect(subject.exclusive_lease.exists?).to be_falsey
    end

    describe 'instrumentation', :request_store do
      it 'increments the lock requested count and computes the duration of holding the lock' do
        subject.call do
          sleep 0.1
        end

        expect(Gitlab::Instrumentation::ExclusiveLock.requested_count).to eq(1)
        expect(Gitlab::Instrumentation::ExclusiveLock.hold_duration).to be_between(0.1, 0.11)
      end

      context 'when exclusive lease is not obtained' do
        before do
          allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
            allow(instance).to receive(:try_obtain).and_return(false)
          end
        end

        it 'increments the lock requested count and does not computes the duration of holding the lock' do
          subject.call do
            sleep 0.1
          end

          expect(Gitlab::Instrumentation::ExclusiveLock.requested_count).to eq(1)
          expect(Gitlab::Instrumentation::ExclusiveLock.hold_duration).to eq(0)
        end
      end

      context 'when an exception is raised during the lease' do
        subject do
          subject_class.new.call do
            sleep 0.1
            raise StandardError
          end
        end

        it 'increments the lock requested count and computes the duration of holding the lock' do
          expect { subject }.to raise_error(StandardError)

          expect(Gitlab::Instrumentation::ExclusiveLock.requested_count).to eq(1)
          expect(Gitlab::Instrumentation::ExclusiveLock.hold_duration).to be_between(0.1, 0.11)
        end
      end
    end

    context 'when the lease is already obtained' do
      before do
        subject.exclusive_lease.try_obtain
      end

      after do
        subject.exclusive_lease.cancel
      end

      context 'when the class does not override lease_taken_log_level' do
        it 'does not call internal_method but logs error', :aggregate_failures do
          expect(subject).not_to receive(:internal_method)
          expect(Gitlab::AppJsonLogger).to receive(:error).with({ message: "Cannot obtain an exclusive lease. There must be another instance already in execution.", lease_key: 'exclusive_lease_guard_test_class', class_name: 'ExclusiveLeaseGuardTestClass', lease_timeout: 1.second })

          subject.call
        end
      end

      context 'when the class overrides lease_taken_log_level to return :info' do
        subject :overwritten_subject_class do
          Class.new(subject_class) do
            def lease_taken_log_level
              :info
            end
          end
        end

        let(:subject) { overwritten_subject_class.new }

        it 'logs info', :aggregate_failures do
          expect(Gitlab::AppJsonLogger).to receive(:info).with({ message: "Cannot obtain an exclusive lease. There must be another instance already in execution.", lease_key: 'exclusive_lease_guard_test_class', class_name: 'ExclusiveLeaseGuardTestClass', lease_timeout: 1.second })

          subject.call
        end
      end

      context 'when the class overrides lease_taken_log_level to return :debug' do
        subject :overwritten_subject_class do
          Class.new(subject_class) do
            def lease_taken_log_level
              :debug
            end
          end
        end

        let(:subject) { overwritten_subject_class.new }

        it 'logs debug', :aggregate_failures do
          expect(Gitlab::AppJsonLogger).to receive(:debug).with({ message: "Cannot obtain an exclusive lease. There must be another instance already in execution.", lease_key: 'exclusive_lease_guard_test_class', class_name: 'ExclusiveLeaseGuardTestClass', lease_timeout: 1.second })

          subject.call
        end
      end
    end

    context 'with overwritten lease_release?' do
      subject :overwritten_subject_class do
        Class.new(subject_class) do
          def lease_release?
            false
          end
        end
      end

      let(:subject) { overwritten_subject_class.new }

      it 'does not release the lease after execution', :aggregate_failures do
        subject.call do
          expect(subject.exclusive_lease.exists?).to be_truthy
        end

        expect(subject.exclusive_lease.exists?).to be_truthy
      end
    end
  end

  describe '#exclusive_lease' do
    it 'uses the class name as lease key' do
      expect(Gitlab::ExclusiveLease).to receive(:new).with('exclusive_lease_guard_test_class', timeout: 1.second)

      subject_class.new.exclusive_lease
    end

    context 'with overwritten lease_key' do
      subject :overwritten_class do
        Class.new(subject_class) do
          def lease_key
            'other_lease_key'
          end
        end
      end

      it 'uses the custom lease key' do
        expect(Gitlab::ExclusiveLease).to receive(:new).with('other_lease_key', timeout: 1.second)

        overwritten_class.new.exclusive_lease
      end
    end
  end

  describe '#release_lease' do
    it 'sends a cancel message to ExclusiveLease' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).with('exclusive_lease_guard_test_class', 'some_uuid')

      subject_class.new.release_lease('some_uuid')
    end
  end

  describe '#renew_lease!' do
    let(:subject) { subject_class.new }

    it 'sends a renew message to the exclusive_lease instance' do
      expect(subject.exclusive_lease).to receive(:renew)
      subject.renew_lease!
    end
  end
end
