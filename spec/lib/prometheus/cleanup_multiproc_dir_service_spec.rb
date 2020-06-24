# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prometheus::CleanupMultiprocDirService do
  describe '.call' do
    subject { described_class.new.execute }

    let(:metrics_multiproc_dir) { Dir.mktmpdir }
    let(:metrics_file_path) { File.join(metrics_multiproc_dir, 'counter_puma_master-0.db') }

    before do
      FileUtils.touch(metrics_file_path)
    end

    after do
      FileUtils.rm_r(metrics_multiproc_dir)
    end

    context 'when `multiprocess_files_dir` is defined' do
      before do
        expect(Prometheus::Client.configuration)
              .to receive(:multiprocess_files_dir)
              .and_return(metrics_multiproc_dir)
              .at_least(:once)
      end

      it 'removes old metrics' do
        expect { subject }
          .to change { File.exist?(metrics_file_path) }
          .from(true)
          .to(false)
      end
    end

    context 'when `multiprocess_files_dir` is not defined' do
      before do
        expect(Prometheus::Client.configuration)
              .to receive(:multiprocess_files_dir)
              .and_return(nil)
              .at_least(:once)
      end

      it 'does not remove any files' do
        expect { subject }
          .not_to change { File.exist?(metrics_file_path) }
          .from(true)
      end
    end
  end
end
