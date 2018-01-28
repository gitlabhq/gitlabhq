require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170921101004_normalize_ldap_extern_uids')

describe NormalizeLdapExternUids, :migration, :sidekiq do
  let!(:identities) { table(:identities) }

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    stub_const("Gitlab::Database::MigrationHelpers::BACKGROUND_MIGRATION_BATCH_SIZE", 2)
    stub_const("Gitlab::Database::MigrationHelpers::BACKGROUND_MIGRATION_JOB_BUFFER_SIZE", 2)

    # LDAP identities
    (1..4).each do |i|
      identities.create!(id: i, provider: 'ldapmain', extern_uid: " uid = foo #{i}, ou = People, dc = example, dc = com ", user_id: i)
    end

    # Non-LDAP identity
    identities.create!(id: 5, provider: 'foo', extern_uid: " uid = foo 5, ou = People, dc = example, dc = com ", user_id: 5)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([described_class::MIGRATION, [1, 2]])
        expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(5.minutes.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([described_class::MIGRATION, [3, 4]])
        expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(10.minutes.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs[2]['args']).to eq([described_class::MIGRATION, [5, 5]])
        expect(BackgroundMigrationWorker.jobs[2]['at']).to eq(15.minutes.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'migrates the LDAP identities' do
    Sidekiq::Testing.inline! do
      migrate!
      identities.where(id: 1..4).each do |identity|
        expect(identity.extern_uid).to eq("uid=foo #{identity.id},ou=people,dc=example,dc=com")
      end
    end
  end

  it 'does not modify non-LDAP identities' do
    Sidekiq::Testing.inline! do
      migrate!
      identity = identities.last
      expect(identity.extern_uid).to eq(" uid = foo 5, ou = People, dc = example, dc = com ")
    end
  end
end
