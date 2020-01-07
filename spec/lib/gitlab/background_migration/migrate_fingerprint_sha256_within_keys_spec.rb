# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateFingerprintSha256WithinKeys, :migration, schema: 20200106071113 do
  subject(:fingerprint_migrator) { described_class.new }

  let(:key_table) { table(:keys) }

  before do
    generate_fingerprints!
  end

  it 'correctly creates a sha256 fingerprint for a key' do
    key_1 = Key.find(1017)
    key_2 = Key.find(1027)

    expect(key_1.fingerprint_md5).to eq('ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1')
    expect(key_1.fingerprint_sha256).to eq(nil)

    expect(key_2.fingerprint_md5).to eq('39:e3:64:a6:24:ea:45:a2:8c:55:2a:e9:4d:4f:1f:b4')
    expect(key_2.fingerprint_sha256).to eq(nil)

    query_count = ActiveRecord::QueryRecorder.new do
      fingerprint_migrator.perform(1, 10000)
    end.count

    expect(query_count).to eq(8)

    key_1.reload
    key_2.reload

    expect(key_1.fingerprint_md5).to eq('ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1')
    expect(key_1.fingerprint_sha256).to eq('nUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo/lCg')

    expect(key_2.fingerprint_md5).to eq('39:e3:64:a6:24:ea:45:a2:8c:55:2a:e9:4d:4f:1f:b4')
    expect(key_2.fingerprint_sha256).to eq('zMNbLekgdjtcgDv8VSC0z5lpdACMG3Q4PUoIz5+H2jM')
  end

  it 'migrates all keys' do
    expect(Key.where(fingerprint_sha256: nil).count).to eq(Key.all.count)

    fingerprint_migrator.perform(1, 10000)

    expect(Key.where(fingerprint_sha256: nil).count).to eq(0)
  end

  def generate_fingerprints!
    values = ""
    (1000..2000).to_a.each do |record|
      key = base_key_for(record)
      fingerprint = fingerprint_for(key)

      values += "(#{record}, #{record}, 'test-#{record}', '#{key}', '#{fingerprint}'),"
    end

    update_query = <<~SQL
      INSERT INTO keys ( id, user_id, title, key, fingerprint )
      VALUES
      #{values.chomp(",")};
    SQL

    ActiveRecord::Base.connection.execute(update_query)
  end

  def base_key_for(record)
    'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt0000k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0='
      .gsub("0000", "%04d" % (record - 1)) # generate arbitrary keys with placeholder 0000 within the key above
  end

  def fingerprint_for(key)
    Gitlab::SSHPublicKey.new(key).fingerprint("md5")
  end
end
