# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reports::JemallocStats do
  let(:reports_dir) {'/empty-dir'}
  let(:jemalloc_stats) { described_class.new(reports_path: reports_dir) }

  describe '.run' do
    context 'when :report_jemalloc_stats ops FF is enabled' do
      let(:worker_id) {'puma_1'}
      let(:report_name) {'report.json'}
      let(:report_path) { File.join(reports_dir, report_name) }

      before do
        allow(Prometheus::PidProvider).to receive(:worker_id).and_return(worker_id)
      end

      it 'invokes Jemalloc.dump_stats and returns file path' do
        expect(Gitlab::Memory::Jemalloc)
          .to receive(:dump_stats).with(path: reports_dir, filename_label: worker_id).and_return(report_path)

        expect(jemalloc_stats.run).to eq(report_path)
      end

      describe 'reports cleanup' do
        let_it_be(:outdir) { Dir.mktmpdir }

        let(:jemalloc_stats) { described_class.new(reports_path: outdir) }

        before do
          stub_env('GITLAB_DIAGNOSTIC_REPORTS_JEMALLOC_MAX_REPORTS_STORED', 3)
          allow(Gitlab::Memory::Jemalloc).to receive(:dump_stats)
        end

        after do
          FileUtils.rm_f(outdir)
        end

        context 'when number of reports exceeds `max_reports_stored`' do
          let_it_be(:reports) do
            now = Time.current

            (1..5).map do |i|
              Tempfile.new("jemalloc_stats.#{i}.worker_#{i}.#{Time.current.to_i}.json", outdir).tap do |f|
                FileUtils.touch(f, mtime: (now + i.second).to_i)
              end
            end
          end

          after do
            reports.each do |f|
              f.close
              f.unlink
            rescue Errno::ENOENT
              # Some of the files are already unlinked by the code we test; Ignore
            end
          end

          it 'keeps only `max_reports_stored` total newest files' do
            expect { jemalloc_stats.run }
              .to change { Dir.entries(outdir).count { |e| e.match(/jemalloc_stats.*/) } }
                    .from(5).to(3)

            # Keeps only the newest reports
            expect(reports.last(3).all? { |r| File.exist?(r) }).to be true
          end
        end

        context 'when number of reports does not exceed `max_reports_stored`' do
          let_it_be(:reports) do
            now = Time.current

            (1..3).map do |i|
              Tempfile.new("jemalloc_stats.#{i}.worker_#{i}.#{Time.current.to_i}.json", outdir).tap do |f|
                FileUtils.touch(f, mtime: (now + i.second).to_i)
              end
            end
          end

          after do
            reports.each do |f|
              f.close
              f.unlink
            end
          end

          it 'does not remove any reports' do
            expect { jemalloc_stats.run }
              .not_to change { Dir.entries(outdir).count { |e| e.match(/jemalloc_stats.*/) } }
          end
        end
      end
    end

    context 'when :report_jemalloc_stats ops FF is disabled' do
      before do
        stub_feature_flags(report_jemalloc_stats: false)
      end

      it 'does not run the report and returns nil' do
        expect(Gitlab::Memory::Jemalloc).not_to receive(:dump_stats)

        expect(jemalloc_stats.run).to be_nil
      end
    end
  end

  describe '.active?' do
    subject(:active) { jemalloc_stats.active? }

    context 'when :report_jemalloc_stats ops FF is enabled' do
      it { is_expected.to be true }
    end

    context 'when :report_jemalloc_stats ops FF is disabled' do
      before do
        stub_feature_flags(report_jemalloc_stats: false)
      end

      it { is_expected.to be false }
    end
  end
end
