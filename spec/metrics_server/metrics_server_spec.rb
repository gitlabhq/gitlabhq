# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../metrics_server/metrics_server'
require_relative '../support/helpers/next_instance_of'

RSpec.describe MetricsServer do # rubocop:disable RSpec/FilePath
  include NextInstanceOf

  describe '.spawn' do
    let(:env) do
      {
        'METRICS_SERVER_TARGET' => 'sidekiq',
        'GITLAB_CONFIG' => nil,
        'WIPE_METRICS_DIR' => 'false'
      }
    end

    it 'spawns a process with the correct environment variables and detaches it' do
      expect(Process).to receive(:spawn).with(env, anything, err: $stderr, out: $stdout).and_return(99)
      expect(Process).to receive(:detach).with(99)

      described_class.spawn('sidekiq')
    end
  end

  describe '#start' do
    let(:exporter_class) { Class.new(Gitlab::Metrics::Exporter::BaseExporter) }
    let(:exporter_double) { double('fake_exporter', start: true) }
    let(:prometheus_client_double) { double(::Prometheus::Client) }
    let(:prometheus_config) { ::Prometheus::Client::Configuration.new }
    let(:metrics_dir) { Dir.mktmpdir }
    let(:settings_double) { double(:settings, sidekiq_exporter: {}) }

    subject(:metrics_server) { described_class.new('fake', metrics_dir, true)}

    before do
      stub_env('prometheus_multiproc_dir', metrics_dir)
      stub_const('Gitlab::Metrics::Exporter::FakeExporter', exporter_class)
      allow(exporter_class).to receive(:instance).with({}, synchronous: true).and_return(exporter_double)
      allow(Settings).to receive(:monitoring).and_return(settings_double)
    end

    after do
      ::Prometheus::CleanupMultiprocDirService.new.execute
      Dir.rmdir(metrics_dir)
    end

    it 'configures ::Prometheus::Client' do
      allow(prometheus_client_double).to receive(:configuration).and_return(prometheus_config)

      metrics_server.start

      expect(prometheus_config.multiprocess_files_dir).to eq metrics_dir
    end

    it 'ensures that metrics directory exists in correct mode (0700)' do
      expect(FileUtils).to receive(:mkdir_p).with(metrics_dir, mode: 0700)

      metrics_server.start
    end

    context 'when wipe_metrics_dir is true' do
      subject(:metrics_server) { described_class.new('fake', metrics_dir, true)}

      it 'removes any old metrics files' do
        FileUtils.touch("#{metrics_dir}/remove_this.db")

        expect { metrics_server.start }.to change { Dir.empty?(metrics_dir) }.from(false).to(true)
      end
    end

    context 'when wipe_metrics_dir is false' do
      subject(:metrics_server) { described_class.new('fake', metrics_dir, false)}

      it 'does not remove any old metrics files' do
        FileUtils.touch("#{metrics_dir}/remove_this.db")

        expect { metrics_server.start }.not_to change { Dir.empty?(metrics_dir) }.from(false)
      end
    end

    it 'starts a metrics server' do
      expect(exporter_double).to receive(:start)

      metrics_server.start
    end

    it 'sends the correct Settings to the exporter instance' do
      expect(Settings).to receive(:monitoring).and_return(settings_double)
      expect(settings_double).to receive(:sidekiq_exporter)

      metrics_server.start
    end
  end
end
