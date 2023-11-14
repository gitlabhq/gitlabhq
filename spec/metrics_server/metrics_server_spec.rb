# frozen_string_literal: true

require 'spec_helper'

require_relative '../../metrics_server/metrics_server'

RSpec.describe MetricsServer, feature_category: :cloud_connector do
  let(:prometheus_config) { ::Prometheus::Client.configuration }
  let(:metrics_dir) { Dir.mktmpdir }

  # Prometheus::Client is a singleton, i.e. shared global state, so
  # we need to reset it after testing.
  let!(:old_multiprocess_files_dir) { prometheus_config.multiprocess_files_dir }

  let(:ruby_sampler_double) { double(Gitlab::Metrics::Samplers::RubySampler) }

  before do
    # Make sure we never actually spawn any new processes in a unit test.
    %i[spawn fork detach].each { |m| allow(Process).to receive(m) }
    # We do not want this to have knock-on effects on the test process.
    allow(Gitlab::ProcessManagement).to receive(:modify_signals)

    # This being a singleton, we stub it out because only one instance is allowed
    # to exist per process.
    allow(Gitlab::Metrics::Samplers::RubySampler).to receive(:initialize_instance).and_return(ruby_sampler_double)
    allow(ruby_sampler_double).to receive(:start)
  end

  after do
    Gitlab::Metrics.reset_registry!
    prometheus_config.multiprocess_files_dir = old_multiprocess_files_dir

    FileUtils.rm_rf(metrics_dir, secure: true)
  end

  %w[puma sidekiq].each do |target|
    context "when targeting #{target}" do
      describe '.fork' do
        context 'when in parent process' do
          it 'forks into a new process and detaches it' do
            expect(Process).to receive(:fork).and_return(99)
            expect(Process).to receive(:detach).with(99)

            described_class.fork(target, metrics_dir: metrics_dir)
          end
        end

        context 'when in child process' do
          before do
            # This signals the process that it's "inside" the fork
            expect(Process).to receive(:fork).and_return(nil)
            expect(Process).not_to receive(:detach)
          end

          it 'starts the metrics server with the given arguments' do
            expect_next_instance_of(MetricsServer) do |server|
              expect(server).to receive(:start)
            end

            described_class.fork(target, metrics_dir: metrics_dir)
          end

          it 'resets signal handlers from parent process' do
            expect(Gitlab::ProcessManagement).to receive(:modify_signals).with(%i[A B], 'DEFAULT')

            described_class.fork(target, metrics_dir: metrics_dir, reset_signals: %i[A B])
          end
        end
      end

      describe '.spawn' do
        let(:expected_env) do
          {
            'METRICS_SERVER_TARGET' => target,
            'WIPE_METRICS_DIR' => '0',
            'GITLAB_CONFIG' => 'path/to/config/gitlab.yml'
          }
        end

        before do
          stub_env('GITLAB_CONFIG', 'path/to/config/gitlab.yml')
        end

        it 'spawns a new server process and returns its PID' do
          expect(Process).to receive(:spawn).with(
            expected_env,
            end_with('bin/metrics-server'),
            hash_including(pgroup: true)
          ).and_return(99)
          expect(Process).to receive(:detach).with(99)

          pid = described_class.spawn(target, metrics_dir: metrics_dir)

          expect(pid).to eq(99)
        end
      end
    end
  end

  context 'when targeting invalid target' do
    describe '.fork' do
      it 'raises an error' do
        expect { described_class.fork('unsupported', metrics_dir: metrics_dir) }.to(
          raise_error('Target must be one of [puma,sidekiq]')
        )
      end
    end

    describe '.spawn' do
      it 'raises an error' do
        expect { described_class.spawn('unsupported', metrics_dir: metrics_dir) }.to(
          raise_error('Target must be one of [puma,sidekiq]')
        )
      end
    end
  end

  shared_examples 'a metrics exporter' do |target, expected_name|
    describe '#start' do
      let(:exporter_double) { double('exporter', start: true) }
      let(:wipe_metrics_dir) { true }

      subject(:metrics_server) { described_class.new(target, metrics_dir, wipe_metrics_dir) }

      it 'configures ::Prometheus::Client' do
        metrics_server.start

        expect(prometheus_config.multiprocess_files_dir).to eq metrics_dir
        expect(::Prometheus::Client.configuration.pid_provider.call).to eq expected_name
      end

      it 'ensures that metrics directory exists in correct mode (0700)' do
        expect(FileUtils).to receive(:mkdir_p).with(metrics_dir, mode: 0700)

        metrics_server.start
      end

      context 'when wipe_metrics_dir is true' do
        it 'removes any old metrics files' do
          FileUtils.touch("#{metrics_dir}/remove_this.db")

          expect { metrics_server.start }.to change { Dir.empty?(metrics_dir) }.from(false).to(true)
        end
      end

      context 'when wipe_metrics_dir is false' do
        let(:wipe_metrics_dir) { false }

        it 'does not remove any old metrics files' do
          FileUtils.touch("#{metrics_dir}/remove_this.db")

          expect { metrics_server.start }.not_to change { Dir.empty?(metrics_dir) }.from(false)
        end
      end

      it 'starts a metrics server' do
        expect(exporter_double).to receive(:start)

        metrics_server.start
      end

      it 'starts a RubySampler instance' do
        expect(ruby_sampler_double).to receive(:start)

        subject.start
      end
    end

    describe '#name' do
      let(:exporter_double) { double('exporter', start: true) }

      subject(:name) { described_class.new(target, metrics_dir, true).name }

      it { is_expected.to eq(expected_name) }
    end
  end

  context 'for puma' do
    before do
      allow(Gitlab::Metrics::Exporter::WebExporter).to receive(:instance).with(
        gc_requests: true, synchronous: true
      ).and_return(exporter_double)
    end

    it_behaves_like 'a metrics exporter', 'puma', 'web_exporter'
  end

  context 'for sidekiq' do
    let(:settings) { GitlabSettings::Options.build({ "sidekiq_exporter" => { "enabled" => true } }) }

    before do
      allow(::Settings).to receive(:monitoring).and_return(settings)
      allow(Gitlab::Metrics::Exporter::SidekiqExporter).to receive(:instance).with(
        settings.sidekiq_exporter, gc_requests: true, synchronous: true
      ).and_return(exporter_double)
    end

    it_behaves_like 'a metrics exporter', 'sidekiq', 'sidekiq_exporter'
  end

  describe '.start_for_puma' do
    let(:supervisor) { instance_double(Gitlab::ProcessSupervisor) }

    before do
      allow(Gitlab::ProcessSupervisor).to receive(:instance).and_return(supervisor)
    end

    it 'spawns a server process and supervises it' do
      expect(Process).to receive(:spawn).with(
        include('METRICS_SERVER_TARGET' => 'puma'), end_with('bin/metrics-server'), anything
      ).once.and_return(42)
      expect(supervisor).to receive(:supervise).with(42)

      described_class.start_for_puma
    end

    context 'when the supervisor callback is invoked' do
      it 'restarts the metrics server' do
        expect(supervisor).to receive(:supervise).and_yield
        expect(Process).to receive(:spawn).with(
          include('METRICS_SERVER_TARGET' => 'puma'), end_with('bin/metrics-server'), anything
        ).twice.and_return(42)

        described_class.start_for_puma
      end
    end
  end

  describe '.start_for_sidekiq' do
    it 'forks the parent process' do
      expect(Process).to receive(:fork).and_return(42)

      described_class.start_for_sidekiq(metrics_dir: '/path/to/metrics')
    end
  end

  describe '.name' do
    subject { described_class.name(target) }

    context 'for puma' do
      let(:target) { 'puma' }

      it { is_expected.to eq 'web_exporter' }
    end

    context 'for sidekiq' do
      let(:target) { 'sidekiq' }

      it { is_expected.to eq 'sidekiq_exporter' }
    end

    context 'for invalid target' do
      let(:target) { 'invalid' }

      it 'raises error' do
        expect { subject }.to raise_error(RuntimeError, "Target must be one of [puma,sidekiq]")
      end
    end
  end
end
