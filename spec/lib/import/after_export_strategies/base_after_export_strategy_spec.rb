# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::AfterExportStrategies::BaseAfterExportStrategy, feature_category: :importers do
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

  describe '#ensure_export_ready!' do
    before do
      service.instance_variable_set(:@project, project)

      allow(service).to receive(:sleep)
    end

    context 'when export file exists on first check' do
      it 'returns without retrying' do
        allow(project).to receive(:export_file_exists?).and_return(true)

        expect { service.ensure_export_ready!(user) }.not_to raise_error
      end
    end

    context 'when export file exists after retries' do
      it 'retries and succeeds' do
        call_count = 0
        allow(project).to receive(:export_file_exists?) do
          call_count += 1
          call_count >= 3
        end

        expect { service.ensure_export_ready!(user, max_retries: 5, base_delay: 0.01) }.not_to raise_error
        expect(call_count).to eq(3)
      end
    end

    context 'when export file never exists' do
      it 'raises StrategyError after max retries' do
        allow(project).to receive(:export_file_exists?).and_return(false)

        expect do
          service.ensure_export_ready!(user, max_retries: 3, base_delay: 0.01)
        end.to raise_error(described_class::StrategyError)
      end

      it 'respects max_retries parameter' do
        call_count = 0
        allow(project).to receive(:export_file_exists?) do
          call_count += 1
          false
        end

        expect do
          service.ensure_export_ready!(user, max_retries: 2, base_delay: 0.01)
        end.to raise_error(described_class::StrategyError)

        expect(call_count).to eq(3) # initial + 2 retries
      end
    end

    describe 'exponential backoff' do
      it 'uses exponential delays between retries' do
        allow(project).to receive(:export_file_exists?).and_return(false)

        expect do
          service.ensure_export_ready!(user, max_retries: 3, base_delay: 1)
        end.to raise_error(described_class::StrategyError)

        expect(service).to have_received(:sleep).with(1).once    # 1 * 2^0
        expect(service).to have_received(:sleep).with(2).once    # 1 * 2^1
        expect(service).to have_received(:sleep).with(4).once    # 1 * 2^2
      end

      it 'uses custom base_delay' do
        allow(project).to receive(:export_file_exists?).and_return(false)
        allow(service).to receive(:sleep)

        expect do
          service.ensure_export_ready!(user, max_retries: 2, base_delay: 2)
        end.to raise_error(described_class::StrategyError)

        expect(service).to have_received(:sleep).with(2).once    # 2 * 2^0
        expect(service).to have_received(:sleep).with(4).once    # 2 * 2^1
      end
    end

    describe 'clearing cached associations' do
      it 'resets import_export_uploads association within uncached block on retry' do
        call_count = 0
        allow(project).to receive(:export_file_exists?) do
          call_count += 1
          call_count >= 2
        end

        association_mock = instance_double(ActiveRecord::Associations::HasManyAssociation)
        allow(project).to receive(:association).with(:import_export_uploads).and_return(association_mock)
        expect(association_mock).to receive(:reset).once
        allow(Project).to receive(:uncached).and_yield

        expect { service.ensure_export_ready!(user, max_retries: 5, base_delay: 0.01) }.not_to raise_error
      end

      it 'does not reset association on first check' do
        allow(project).to receive(:export_file_exists?).and_return(true)

        expect(project).not_to receive(:association)

        service.ensure_export_ready!(user)
      end

      it 'uses uncached block when clearing association on retry' do
        call_count = 0
        allow(project).to receive(:export_file_exists?) do
          call_count += 1
          call_count >= 2
        end

        expect(Project).to receive(:uncached).once.and_yield

        service.ensure_export_ready!(user, max_retries: 5, base_delay: 0.01)
      end
    end
  end
end
