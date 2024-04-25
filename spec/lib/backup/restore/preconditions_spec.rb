# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Backup::Restore::Preconditions, feature_category: :backup_restore do
  let(:logger) { Gitlab::BackupLogger.new(StringIO.new) }
  let(:gitlab_version) { '16.11' }
  let(:backup_information) do
    {
      backup_created_at: Time.zone.parse('2019-01-01'),
      gitlab_version: gitlab_version
    }
  end

  subject(:preconditions) do
    described_class.new(
      backup_information: backup_information,
      logger: logger)
  end

  before do
    allow_next_instance_of(Backup::Metadata) do |metadata|
      allow(metadata).to receive(:load_from_file).and_return(backup_information)
    end
  end

  describe '#ensure_supported_backup_version!' do
    context 'when version matches' do
      it 'does not raise error and terminate process' do
        stub_const('Gitlab::VERSION', gitlab_version)

        expect { preconditions.ensure_supported_backup_version! }.not_to raise_error
      end
    end

    context 'when version mismatches' do
      it 'display a message and stop the process with exit 1' do
        stub_const('Gitlab::VERSION', '15.0')

        expect(logger).to receive(:error).with(a_string_matching('GitLab version mismatch')).ordered
        expect(logger).to receive(:error).with(a_string_matching('Hint: git checkout v16.11')).ordered

        expect { preconditions.ensure_supported_backup_version! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end

  describe '#validate_backup_version!' do
    context 'when version matches' do
      it 'display a message and stop the process with exit 0' do
        stub_const('Gitlab::VERSION', gitlab_version)

        expect(logger).to receive(:info).with(a_string_matching('GitLab version matches')).ordered

        expect { preconditions.validate_backup_version! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context 'when version mismatches' do
      it 'display a message and stop the process with exit 1' do
        stub_const('Gitlab::VERSION', '15.0')

        expect(logger).to receive(:error).with(a_string_matching('GitLab version mismatch')).ordered
        expect(logger).to receive(:error).with(a_string_matching('Hint: git checkout v16.11')).ordered

        expect { preconditions.validate_backup_version! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end
end
