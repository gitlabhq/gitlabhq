# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SidekiqCluster::CLI do
  let(:cli) { described_class.new('/dev/null') }
  let(:timeout) { described_class::DEFAULT_SOFT_TIMEOUT_SECONDS }
  let(:default_options) do
    { env: 'test', directory: Dir.pwd, max_concurrency: 50, min_concurrency: 0, dryrun: false, timeout: timeout }
  end

  before do
    stub_env('RAILS_ENV', 'test')
  end

  describe '#run' do
    context 'without any arguments' do
      it 'raises CommandError' do
        expect { cli.run([]) }.to raise_error(described_class::CommandError)
      end
    end

    context 'with arguments' do
      before do
        allow(cli).to receive(:write_pid)
        allow(cli).to receive(:trap_signals)
        allow(cli).to receive(:start_loop)
      end

      it 'starts the Sidekiq workers' do
        expect(Gitlab::SidekiqCluster).to receive(:start)
                                            .with([['foo']], default_options)
                                            .and_return([])

        cli.run(%w(foo))
      end

      it 'allows the special * selector' do
        worker_queues = %w(foo bar baz)

        expect(Gitlab::SidekiqConfig::CliMethods)
          .to receive(:worker_queues).and_return(worker_queues)

        expect(Gitlab::SidekiqCluster)
          .to receive(:start).with([worker_queues], default_options)

        cli.run(%w(*))
      end

      context 'with --negate flag' do
        it 'starts Sidekiq workers for all queues in all_queues.yml except the ones in argv' do
          expect(Gitlab::SidekiqConfig::CliMethods).to receive(:worker_queues).and_return(['baz'])
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([['baz']], default_options)
                                              .and_return([])

          cli.run(%w(foo -n))
        end
      end

      context 'with --max-concurrency flag' do
        it 'starts Sidekiq workers for specified queues with a max concurrency' do
          expect(Gitlab::SidekiqConfig::CliMethods).to receive(:worker_queues).and_return(%w(foo bar baz))
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([%w(foo bar baz), %w(solo)], default_options.merge(max_concurrency: 2))
                                              .and_return([])

          cli.run(%w(foo,bar,baz solo -m 2))
        end
      end

      context 'with --min-concurrency flag' do
        it 'starts Sidekiq workers for specified queues with a min concurrency' do
          expect(Gitlab::SidekiqConfig::CliMethods).to receive(:worker_queues).and_return(%w(foo bar baz))
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([%w(foo bar baz), %w(solo)], default_options.merge(min_concurrency: 2))
                                              .and_return([])

          cli.run(%w(foo,bar,baz solo --min-concurrency 2))
        end
      end

      context '-timeout flag' do
        it 'when given', 'starts Sidekiq workers with given timeout' do
          expect(Gitlab::SidekiqCluster).to receive(:start)
            .with([['foo']], default_options.merge(timeout: 10))

          cli.run(%w(foo --timeout 10))
        end

        it 'when not given', 'starts Sidekiq workers with default timeout' do
          expect(Gitlab::SidekiqCluster).to receive(:start)
            .with([['foo']], default_options.merge(timeout: described_class::DEFAULT_SOFT_TIMEOUT_SECONDS))

          cli.run(%w(foo))
        end
      end

      context 'queue namespace expansion' do
        it 'starts Sidekiq workers for all queues in all_queues.yml with a namespace in argv' do
          expect(Gitlab::SidekiqConfig::CliMethods).to receive(:worker_queues).and_return(['cronjob:foo', 'cronjob:bar'])
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([['cronjob', 'cronjob:foo', 'cronjob:bar']], default_options)
                                              .and_return([])

          cli.run(%w(cronjob))
        end
      end

      context "with --queue-selector" do
        where do
          {
            'memory-bound queues' => {
              query: 'resource_boundary=memory',
              included_queues: %w(project_export),
              excluded_queues: %w(merge)
            },
            'memory- or CPU-bound queues' => {
              query: 'resource_boundary=memory,cpu',
              included_queues: %w(auto_merge:auto_merge_process project_export),
              excluded_queues: %w(merge)
            },
            'high urgency CI queues' => {
              query: 'feature_category=continuous_integration&urgency=high',
              included_queues: %w(pipeline_cache:expire_job_cache pipeline_cache:expire_pipeline_cache),
              excluded_queues: %w(merge)
            },
            'CPU-bound high urgency CI queues' => {
              query: 'feature_category=continuous_integration&urgency=high&resource_boundary=cpu',
              included_queues: %w(pipeline_cache:expire_pipeline_cache),
              excluded_queues: %w(pipeline_cache:expire_job_cache merge)
            },
            'CPU-bound high urgency non-CI queues' => {
              query: 'feature_category!=continuous_integration&urgency=high&resource_boundary=cpu',
              included_queues: %w(new_issue),
              excluded_queues: %w(pipeline_cache:expire_pipeline_cache)
            },
            'CI and SCM queues' => {
              query: 'feature_category=continuous_integration|feature_category=source_code_management',
              included_queues: %w(pipeline_cache:expire_job_cache merge),
              excluded_queues: %w(mailers)
            }
          }
        end

        with_them do
          it 'expands queues by attributes' do
            expect(Gitlab::SidekiqCluster).to receive(:start) do |queues, opts|
              expect(opts).to eq(default_options)
              expect(queues.first).to include(*included_queues)
              expect(queues.first).not_to include(*excluded_queues)

              []
            end

            cli.run(%W(--queue-selector #{query}))
          end

          it 'works when negated' do
            expect(Gitlab::SidekiqCluster).to receive(:start) do |queues, opts|
              expect(opts).to eq(default_options)
              expect(queues.first).not_to include(*included_queues)
              expect(queues.first).to include(*excluded_queues)

              []
            end

            cli.run(%W(--negate --queue-selector #{query}))
          end
        end

        it 'expands multiple queue groups correctly' do
          expect(Gitlab::SidekiqCluster)
            .to receive(:start)
                  .with([['chat_notification'], ['project_export']], default_options)
                  .and_return([])

          cli.run(%w(--queue-selector feature_category=chatops&has_external_dependencies=true resource_boundary=memory&feature_category=importers))
        end

        it 'allows the special * selector' do
          worker_queues = %w(foo bar baz)

          expect(Gitlab::SidekiqConfig::CliMethods)
            .to receive(:worker_queues).and_return(worker_queues)

          expect(Gitlab::SidekiqCluster)
            .to receive(:start).with([worker_queues], default_options)

          cli.run(%w(--queue-selector *))
        end

        it 'errors when the selector matches no queues' do
          expect(Gitlab::SidekiqCluster).not_to receive(:start)

          expect { cli.run(%w(--queue-selector has_external_dependencies=true&has_external_dependencies=false)) }
            .to raise_error(described_class::CommandError)
        end

        it 'errors on an invalid query multiple queue groups correctly' do
          expect(Gitlab::SidekiqCluster).not_to receive(:start)

          expect { cli.run(%w(--queue-selector unknown_field=chatops)) }
            .to raise_error(Gitlab::SidekiqConfig::WorkerMatcher::QueryError)
        end
      end
    end
  end

  describe '#write_pid' do
    context 'when a PID is specified' do
      it 'writes the PID to a file' do
        expect(Gitlab::SidekiqCluster).to receive(:write_pid).with('/dev/null')

        cli.option_parser.parse!(%w(-P /dev/null))
        cli.write_pid
      end
    end

    context 'when no PID is specified' do
      it 'does not write a PID' do
        expect(Gitlab::SidekiqCluster).not_to receive(:write_pid)

        cli.write_pid
      end
    end
  end

  describe '#wait_for_termination' do
    it 'waits for termination of all sub-processes and succeeds after 3 checks' do
      expect(Gitlab::SidekiqCluster).to receive(:any_alive?)
        .with(an_instance_of(Array)).and_return(true, true, true, false)

      expect(Gitlab::SidekiqCluster).to receive(:pids_alive)
        .with([]).and_return([])

      expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
        .with([], "-KILL")

      stub_const("Gitlab::SidekiqCluster::CLI::CHECK_TERMINATE_INTERVAL_SECONDS", 0.1)
      allow(cli).to receive(:terminate_timeout_seconds) { 1 }

      cli.wait_for_termination
    end

    context 'with hanging workers' do
      before do
        expect(cli).to receive(:write_pid)
        expect(cli).to receive(:trap_signals)
        expect(cli).to receive(:start_loop)
      end

      it 'hard kills workers after timeout expires' do
        worker_pids = [101, 102, 103]
        expect(Gitlab::SidekiqCluster).to receive(:start)
                                            .with([['foo']], default_options)
                                            .and_return(worker_pids)

        expect(Gitlab::SidekiqCluster).to receive(:any_alive?)
          .with(worker_pids).and_return(true).at_least(10).times

        expect(Gitlab::SidekiqCluster).to receive(:pids_alive)
          .with(worker_pids).and_return([102])

        expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
          .with([102], "-KILL")

        cli.run(%w(foo))

        stub_const("Gitlab::SidekiqCluster::CLI::CHECK_TERMINATE_INTERVAL_SECONDS", 0.1)
        allow(cli).to receive(:terminate_timeout_seconds) { 1 }

        cli.wait_for_termination
      end
    end
  end

  describe '#trap_signals' do
    it 'traps the termination and forwarding signals' do
      expect(Gitlab::SidekiqCluster).to receive(:trap_terminate)
      expect(Gitlab::SidekiqCluster).to receive(:trap_forward)

      cli.trap_signals
    end
  end

  describe '#start_loop' do
    it 'runs until one of the processes has been terminated' do
      allow(cli).to receive(:sleep).with(a_kind_of(Numeric))

      expect(Gitlab::SidekiqCluster).to receive(:all_alive?)
        .with(an_instance_of(Array)).and_return(false)

      expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
        .with(an_instance_of(Array), :TERM)

      cli.start_loop
    end
  end
end
