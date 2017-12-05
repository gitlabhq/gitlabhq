require 'rails_helper'

describe Gitlab::SidekiqConfig do
  describe '.workers' do
    it 'includes all workers' do
      workers = described_class.workers

      expect(workers).to include(PostReceive)
      expect(workers).to include(MergeWorker)
    end

    it 'includes EE workers' do
      workers = described_class.workers

      expect(workers).to include(RepositoryUpdateMirrorWorker)
      expect(workers).to include(LdapGroupSyncWorker)
    end
  end

  describe '.worker_queues' do
    it 'includes all queues' do
      queues = described_class.worker_queues

      expect(queues).to include('post_receive')
      expect(queues).to include('merge')
      expect(queues).to include('cronjob')
      expect(queues).to include('mailers')
      expect(queues).to include('default')
    end

    it 'includes EE queues' do
      queues = described_class.worker_queues

      expect(queues).to include('repository_update_mirror')
      expect(queues).to include('ldap_group_sync')
    end
  end
end
