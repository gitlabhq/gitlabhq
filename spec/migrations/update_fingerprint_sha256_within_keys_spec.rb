# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateFingerprintSha256WithinKeys do
  let(:key_table) { table(:keys) }

  describe '#up' do
    it 'the BackgroundMigrationWorker will be triggered and fingerprint_sha256 populated' do
      key_table.create!(
        id: 1,
        user_id: 1,
        title: 'test',
        key: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=',
        fingerprint: 'ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1',
        fingerprint_sha256: nil
      )

      expect(Key.first.fingerprint_sha256).to eq(nil)

      described_class.new.up

      expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      expect(BackgroundMigrationWorker.jobs.first["args"][0]).to eq("MigrateFingerprintSha256WithinKeys")
      expect(BackgroundMigrationWorker.jobs.first["args"][1]).to eq([1, 1])
    end
  end
end
