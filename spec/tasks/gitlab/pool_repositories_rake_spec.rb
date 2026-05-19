# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:pool_repositories namespace rake task', :silence_stdout, feature_category: :source_code_management do
  before do
    Rake.application.rake_require 'tasks/gitlab/pool_repositories'
  end

  def reset_logger!
    Gitlab::PoolRepositories::RakeTask.remove_instance_variable(:@logger) if
      Gitlab::PoolRepositories::RakeTask.instance_variable_defined?(:@logger)
  end

  describe 'Gitlab::PoolRepositories::RakeTask.logger' do
    subject(:logger) { Gitlab::PoolRepositories::RakeTask.logger }

    before do
      reset_logger!
    end

    after do
      reset_logger!
    end

    shared_examples 'a broadcast logger environment' do |env_name|
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env_name))
      end

      it { is_expected.to be_a(ActiveSupport::BroadcastLogger) }

      it 'broadcasts to both stdout and Rails.logger' do
        expect(logger.broadcasts.size).to eq(2)
      end
    end

    context 'in development environment' do
      include_examples 'a broadcast logger environment', 'development'
    end

    context 'in production environment' do
      include_examples 'a broadcast logger environment', 'production'
    end

    context 'in test environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
      end

      it { is_expected.to eq(Rails.logger) }
    end

    it 'memoizes the logger' do
      logger1 = Gitlab::PoolRepositories::RakeTask.logger
      logger2 = Gitlab::PoolRepositories::RakeTask.logger

      expect(logger1).to be(logger2)
    end
  end

  describe 'discover_orphaned' do
    subject(:run_task) { run_rake_task(task_name) }

    let(:task_name) { 'gitlab:pool_repositories:discover_orphaned' }
    let(:discoverer) { instance_double(Gitlab::PoolRepositories::OrphanedDiscoverer) }
    let(:logger) { instance_double(Logger, info: nil) }

    before do
      Rake::Task[task_name].reenable
      allow(Gitlab::PoolRepositories::RakeTask).to receive(:logger).and_return(logger)
      allow(Gitlab::PoolRepositories::OrphanedDiscoverer).to receive(:new).and_return(discoverer)
      allow(discoverer).to receive(:run!)
    end

    shared_examples 'passes env var as option' do |env_var, option_key, env_value, expected_value|
      before do
        stub_env(env_var, env_value)
      end

      it "passes #{option_key}: #{expected_value.inspect}" do
        run_task

        expect(Gitlab::PoolRepositories::OrphanedDiscoverer).to have_received(:new).with(
          hash_including(option_key => expected_value)
        )
      end
    end

    context 'when VERBOSE=true' do
      before do
        stub_env('OUTPUT_FILE', '/tmp/test_output.csv')
      end

      include_examples 'passes env var as option', 'VERBOSE', :verbose, 'true', true
    end

    context 'when VERBOSE is not set' do
      before do
        stub_env('OUTPUT_FILE', '/tmp/test_output.csv')
      end

      include_examples 'passes env var as option', 'VERBOSE', :verbose, nil, false
    end

    context 'when OUTPUT_FILE is not set' do
      before do
        stub_env('OUTPUT_FILE', nil)
        allow(logger).to receive(:error)
      end

      it 'logs an error and exits' do
        expect { run_task }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        expect(logger).to have_received(:error).with(/OUTPUT_FILE environment variable is required/)
      end

      it 'does not create a discoverer' do
        expect { run_task }.to raise_error(SystemExit)
        expect(Gitlab::PoolRepositories::OrphanedDiscoverer).not_to have_received(:new)
      end
    end

    context 'when OUTPUT_FILE is set' do
      before do
        stub_env('OUTPUT_FILE', '/tmp/test_output.csv')
      end

      include_examples 'passes env var as option', 'OUTPUT_FILE', :output_file, '/tmp/test_output.csv',
        '/tmp/test_output.csv'

      it 'creates a discoverer and runs it' do
        run_task

        expect(Gitlab::PoolRepositories::OrphanedDiscoverer).to have_received(:new).with(
          logger: logger,
          output_file: '/tmp/test_output.csv',
          verbose: false
        )
        expect(discoverer).to have_received(:run!)
      end

      it 'logs completion message with file path' do
        run_task

        expect(logger).to have_received(:info).with(/Results saved to/)
      end
    end
  end
end
