# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LimitedCapacity::JobTracker, :clean_gitlab_redis_queues do
  let(:job_tracker) do
    described_class.new('namespace')
  end

  describe '#register' do
    it 'adds jid to the set' do
      job_tracker.register('a-job-id')

      expect(job_tracker.running_jids).to contain_exactly('a-job-id')
    end

    it 'updates the counter' do
      expect { job_tracker.register('a-job-id') }
        .to change { job_tracker.count }
        .from(0)
        .to(1)
    end

    it 'does it in only one Redis call' do
      expect(job_tracker).to receive(:with_redis).once.and_call_original

      job_tracker.register('a-job-id')
    end
  end

  describe '#remove' do
    before do
      job_tracker.register(%w[a-job-id other-job-id])
    end

    it 'removes jid from the set' do
      job_tracker.remove('other-job-id')

      expect(job_tracker.running_jids).to contain_exactly('a-job-id')
    end

    it 'updates the counter' do
      expect { job_tracker.remove('other-job-id') }
        .to change { job_tracker.count }
        .from(2)
        .to(1)
    end

    it 'does it in only one Redis call' do
      expect(job_tracker).to receive(:with_redis).once.and_call_original

      job_tracker.remove('other-job-id')
    end
  end

  describe '#clean_up' do
    before do
      job_tracker.register('a-job-id')
    end

    context 'with running jobs' do
      before do
        expect(Gitlab::SidekiqStatus).to receive(:completed_jids)
          .with(%w[a-job-id])
          .and_return([])
      end

      it 'does not remove the jid from the set' do
        expect { job_tracker.clean_up }
          .not_to change { job_tracker.running_jids.include?('a-job-id') }
      end

      it 'does only one Redis call to get the job ids' do
        expect(job_tracker).to receive(:with_redis).once.and_call_original

        job_tracker.clean_up
      end
    end

    context 'with completed jobs' do
      it 'removes the jid from the set' do
        expect { job_tracker.clean_up }
          .to change { job_tracker.running_jids.include?('a-job-id') }
      end

      it 'updates the counter' do
        expect { job_tracker.clean_up }
          .to change { job_tracker.count }
          .from(1)
          .to(0)
      end

      it 'gets the job ids, removes them, and updates the counter with only two Redis calls' do
        expect(job_tracker).to receive(:with_redis).twice.and_call_original

        job_tracker.clean_up
      end
    end
  end
end
