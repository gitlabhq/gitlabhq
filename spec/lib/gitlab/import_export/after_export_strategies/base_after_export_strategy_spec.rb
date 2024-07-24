# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AfterExportStrategies::BaseAfterExportStrategy do
  before do
    allow_next_instance_of(ProjectExportWorker) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
  end

  let!(:service) { described_class.new }
  let!(:project) { create(:project, :with_export, creator: user) }
  let(:shared) { project.import_export_shared }
  let!(:user) { create(:user) }

  describe '#execute' do
    before do
      allow(service).to receive(:strategy_execute)
    end

    it 'returns if project exported file is not found' do
      allow(project).to receive(:export_file_exists?).and_return(false)

      expect(service).not_to receive(:strategy_execute)

      service.execute(user, project)
    end

    it 'creates a lock file in the export dir' do
      allow(service).to receive(:delete_after_export_lock)

      service.execute(user, project)

      expect(service.locks_present?).to be_truthy
    end

    context 'when the method succeeds' do
      it 'removes the lock file' do
        service.execute(user, project)

        expect(service.locks_present?).to be_falsey
      end

      it 'removes the archive path' do
        FileUtils.mkdir_p(shared.archive_path)

        service.execute(user, project)

        expect(File.exist?(shared.archive_path)).to be_falsey
      end
    end

    context 'when the method fails' do
      before do
        allow(service).to receive(:strategy_execute).and_call_original
      end

      context 'when validation fails' do
        before do
          allow(service).to receive(:invalid?).and_return(true)
        end

        it 'does not create the lock file' do
          expect(service).not_to receive(:create_or_update_after_export_lock)

          service.execute(user, project)
        end

        it 'does not execute main logic' do
          expect(service).not_to receive(:strategy_execute)

          service.execute(user, project)
        end

        it 'logs validation errors in shared context' do
          expect(service).to receive(:log_validation_errors)

          service.execute(user, project)
        end

        it 'removes the archive path' do
          FileUtils.mkdir_p(shared.archive_path)

          service.execute(user, project)

          expect(File.exist?(shared.archive_path)).to be_falsey
        end
      end

      context 'when an exception is raised' do
        it 'removes the lock' do
          expect { service.execute(user, project) }.to raise_error(NotImplementedError)

          expect(service.locks_present?).to be_falsey
        end
      end
    end
  end

  describe '#log_validation_errors' do
    it 'add the message to the shared context' do
      errors = %w[test_message test_message2]

      allow(service).to receive(:invalid?).and_return(true)
      allow(service.errors).to receive(:full_messages).and_return(errors)

      expect(shared).to receive(:add_error_message).twice.and_call_original

      service.execute(user, project)

      expect(shared.errors).to eq errors
    end
  end

  describe '#to_json' do
    it 'adds the current strategy class to the serialized attributes' do
      params = { param1: 1 }
      result = params.merge(klass: described_class.to_s).to_json

      expect(described_class.new(params).to_json).to eq result
    end
  end
end
