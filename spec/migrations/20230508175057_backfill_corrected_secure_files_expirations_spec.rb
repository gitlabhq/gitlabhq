# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillCorrectedSecureFilesExpirations, migration: :gitlab_ci, feature_category: :mobile_devops do
  let(:migration) { described_class.new }
  let(:ci_secure_files) { table(:ci_secure_files) }

  let!(:file1) { ci_secure_files.create!(project_id: 1, name: "file.cer", file: "foo", checksum: 'bar') }
  let!(:file2) { ci_secure_files.create!(project_id: 1, name: "file.p12", file: "foo", checksum: 'bar') }
  let!(:file3) { ci_secure_files.create!(project_id: 1, name: "file.jks", file: "foo", checksum: 'bar') }

  describe '#up' do
    it 'enqueues the ParseSecureFileMetadataWorker job for relevant file types', :aggregate_failures do
      expect(::Ci::ParseSecureFileMetadataWorker).to receive(:perform_async).with(file1.id)
      expect(::Ci::ParseSecureFileMetadataWorker).to receive(:perform_async).with(file2.id)
      expect(::Ci::ParseSecureFileMetadataWorker).not_to receive(:perform_async).with(file3.id)

      migration.up
    end
  end
end
