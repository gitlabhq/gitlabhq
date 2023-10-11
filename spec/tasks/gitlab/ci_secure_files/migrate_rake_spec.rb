# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:ci_secure_files', feature_category: :mobile_devops do
  let!(:local_file) { create(:ci_secure_file) }

  let(:logger) { instance_double(Logger) }
  let(:helper) { double }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/ci_secure_files/migrate'
  end

  before do
    allow(Logger).to receive(:new).with($stdout).and_return(logger)
  end

  describe 'gitlab:ci_secure_files:migrate' do
    subject { run_rake_task('gitlab:ci_secure_files:migrate') }

    it 'invokes the migration helper to move files to object storage' do
      expect(Gitlab::Ci::SecureFiles::MigrationHelper).to receive(:migrate_to_remote_storage).and_yield(local_file)
      expect(logger).to receive(:info).with('Starting transfer of Secure Files to object storage')
      expect(logger).to receive(:info).with(/Transferred Secure File ID #{local_file.id}/)

      subject
    end

    context 'when an error is raised while migrating' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(Gitlab::Ci::SecureFiles::MigrationHelper).to receive(:migrate_to_remote_storage).and_raise(StandardError,
          error_message)
      end

      it 'logs the error' do
        expect(logger).to receive(:info).with('Starting transfer of Secure Files to object storage')
        expect(logger).to receive(:error).with("Failed to migrate: #{error_message}")

        subject
      end
    end
  end
end
