# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleFillValidTimeForPagesDomainCertificates do
  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:domains_table) { table(:pages_domains) }

  let(:certificate) do
    File.read('spec/fixtures/passphrase_x509_certificate.crt')
  end

  before do
    domains_table.create!(domain: "domain1.example.com", verification_code: "123")
    domains_table.create!(domain: "domain2.example.com", verification_code: "123", certificate: '')
    domains_table.create!(domain: "domain3.example.com", verification_code: "123", certificate: certificate)
    domains_table.create!(domain: "domain4.example.com", verification_code: "123", certificate: certificate)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        first_id = domains_table.find_by_domain("domain3.example.com").id
        last_id = domains_table.find_by_domain("domain4.example.com").id

        expect(migration_name).to be_scheduled_delayed_migration(5.minutes, first_id, last_id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end

  it 'sets certificate valid_not_before/not_after', :sidekiq_might_not_need_inline do
    perform_enqueued_jobs do
      migrate!

      domain = domains_table.find_by_domain("domain3.example.com")
      expect(domain.certificate_valid_not_before)
        .to eq(Time.parse("2018-03-23 14:02:08 UTC"))
      expect(domain.certificate_valid_not_after)
        .to eq(Time.parse("2019-03-23 14:02:08 UTC"))
    end
  end
end
