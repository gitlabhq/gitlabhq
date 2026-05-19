# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::FileDownloadStrategy, feature_category: :importers do
  subject(:strategy) { described_class.new }

  describe '#download_file' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:filename) { 'repository.tar.gz' }
    let(:filepath) { File.join(tmpdir, filename) }

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it { expect { strategy.download_file(filepath) }.to raise_exception(Gitlab::AbstractMethodError) }

    context 'when download strategy is implemented' do
      let(:mock_strategy_class) do
        Class.new(described_class) do
          def perform_download(filepath)
            FileUtils.touch(filepath) # Ensure mock downloaded file exists on disk for symlink validation
          end
        end
      end

      subject(:strategy) { mock_strategy_class.new }

      it { expect { strategy.download_file(filepath) }.not_to raise_exception }

      context 'when dir path is being traversed' do
        let(:tmpdir) { File.join(Dir.mktmpdir('bulk_imports'), 'test', '..') }

        it 'raises an error' do
          expect { strategy.download_file(filepath) }.to raise_error(
            Gitlab::PathTraversal::PathTraversalAttackError,
            'Invalid path'
          )
        end
      end

      context 'when validating file download size' do
        let(:mock_strategy_class) do
          Class.new(described_class) do
            def perform_download(_filepath)
              stub_file_size = 1.kilobyte
              validate_size!(stub_file_size)
            end
          end
        end

        subject(:strategy) { mock_strategy_class.new }

        it 'must also implement file_size_limit', :aggregate_failures do
          # Prevent false passes from perform_download not being implemented
          expect(strategy).to receive(:validate_size!).and_call_original

          expect { strategy.download_file(filepath) }.to raise_exception(Gitlab::AbstractMethodError)
        end
      end

      context 'when file is a symlink' do
        let(:filename) { 'symlink' }
        let(:symlink) { File.join(tmpdir, filename) }
        let(:linked_filename) { 'file_download_service_spec' }

        before do
          FileUtils.ln_s(File.join(tmpdir, linked_filename), symlink, force: true)
        end

        it 'raises an error and removes the file' do
          expect { strategy.download_file(filepath) }.to raise_error(
            Import::BulkImports::FileDownloadStrategy::ServiceError,
            'Invalid downloaded file'
          )

          expect(File.exist?(symlink)).to be(false)
        end
      end

      context 'when file shares multiple hard links' do
        let(:filename) { 'hard_link' }
        let(:hard_link) { File.join(tmpdir, filename) }

        before do
          existing_file = File.join(Dir.mktmpdir, filename)
          FileUtils.touch(existing_file)
          FileUtils.link(existing_file, hard_link)
        end

        it 'raises an error and removes the file' do
          expect { strategy.download_file(filepath) }.to raise_error(
            Import::BulkImports::FileDownloadStrategy::ServiceError,
            'Invalid downloaded file'
          )

          expect(File.exist?(hard_link)).to be(false)
        end
      end
    end
  end

  describe '#log_and_raise_error' do
    let(:import_logger) { instance_double(BulkImports::Logger) }

    before do
      allow(BulkImports::Logger).to receive(:build).and_return(import_logger)
      allow(import_logger).to receive(:warn)
    end

    it 'logs the message and raises a ServiceError with the given message', :aggregate_failures do
      message = 'something went wrong'

      expect(import_logger).to receive(:warn).with(hash_including(message: message))
      expect { strategy.log_and_raise_error(message) }.to raise_error(
        Import::BulkImports::FileDownloadStrategy::ServiceError,
        message
      )
    end
  end

  describe '#validate!' do
    it { expect { strategy.validate! }.to raise_exception(Gitlab::AbstractMethodError) }
  end
end
