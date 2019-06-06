require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180216121030_enqueue_verify_pages_domain_workers')

describe EnqueueVerifyPagesDomainWorkers, :sidekiq, :migration do
  around do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  let(:domains_table) { table(:pages_domains) }

  describe '#up' do
    it 'enqueues a verification worker for every domain' do
      domains = Array.new(3) do |i|
        domains_table.create!(domain: "my#{i}.domain.com", verification_code: "123#{i}")
      end

      expect { migrate! }.to change(PagesDomainVerificationWorker.jobs, :size).by(3)

      enqueued_ids = PagesDomainVerificationWorker.jobs.map { |job| job['args'] }
      expected_ids = domains.map { |domain| [domain.id] }

      expect(enqueued_ids).to match_array(expected_ids)
    end
  end
end
