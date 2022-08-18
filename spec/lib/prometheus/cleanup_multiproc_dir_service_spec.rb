# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'

RSpec.describe Prometheus::CleanupMultiprocDirService do
  describe '#execute' do
    let(:metrics_multiproc_dir) { Dir.mktmpdir }
    let(:metrics_file_path) { File.join(metrics_multiproc_dir, 'counter_puma_master-0.db') }

    subject(:service) { described_class.new(metrics_dir_arg).execute }

    before do
      FileUtils.touch(metrics_file_path)
    end

    after do
      FileUtils.rm_rf(metrics_multiproc_dir)
    end

    context 'when `multiprocess_files_dir` is defined' do
      let(:metrics_dir_arg) { metrics_multiproc_dir }

      it 'removes old metrics' do
        expect { service }
          .to change { File.exist?(metrics_file_path) }
          .from(true)
          .to(false)
      end
    end

    context 'when `multiprocess_files_dir` is not defined' do
      let(:metrics_dir_arg) { nil }

      it 'does not remove any files' do
        expect { service }
          .not_to change { File.exist?(metrics_file_path) }
          .from(true)
      end
    end
  end
end
