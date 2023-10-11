# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:terraform_states', :silence_stdout do
  let!(:version) { create(:terraform_state_version) }

  let(:logger) { instance_double(Logger) }
  let(:helper) { double }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/terraform/migrate'
  end

  before do
    allow(Logger).to receive(:new).with($stdout).and_return(logger)
  end

  describe 'gitlab:terraform_states:migrate' do
    subject { run_rake_task('gitlab:terraform_states:migrate') }

    it 'invokes the migration helper to move files to object storage' do
      expect(Gitlab::Terraform::StateMigrationHelper).to receive(:migrate_to_remote_storage).and_yield(version)
      expect(logger).to receive(:info).with('Starting transfer of Terraform states to object storage')
      expect(logger).to receive(:info).with(/Transferred Terraform state version ID #{version.id}/)

      subject
    end

    context 'an error is raised while migrating' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(Gitlab::Terraform::StateMigrationHelper).to receive(:migrate_to_remote_storage).and_raise(StandardError, error_message)
      end

      it 'logs the error' do
        expect(logger).to receive(:info).with('Starting transfer of Terraform states to object storage')
        expect(logger).to receive(:error).with("Failed to migrate: #{error_message}")

        subject
      end
    end
  end
end
