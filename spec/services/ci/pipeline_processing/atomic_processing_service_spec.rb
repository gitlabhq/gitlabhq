# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineProcessing::AtomicProcessingService, feature_category: :continuous_integration do
  include RepoHelpers
  include ExclusiveLeaseHelpers

  describe 'Pipeline Processing Service Tests With Yaml' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    where(:test_file_path) do
      Dir.glob(Rails.root.join('spec/services/ci/pipeline_processing/test_cases/*.yml'))
    end

    with_them do
      let(:test_file) { YAML.load_file(test_file_path) }
      let(:pipeline) { Ci::CreatePipelineService.new(project, user, ref: 'master').execute(:pipeline).payload }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(test_file['config']))
      end

      it 'follows transitions' do
        expect(pipeline).to be_persisted
        Sidekiq::Worker.drain_all # ensure that all async jobs are executed
        check_expectation(test_file.dig('init', 'expect'), "init")

        test_file['transitions'].each_with_index do |transition, idx|
          process_events(transition)
          Sidekiq::Worker.drain_all # ensure that all async jobs are executed
          check_expectation(transition['expect'], "transition:#{idx}")
        end
      end

      private

      def check_expectation(expectation, message)
        expect(current_state.deep_stringify_keys).to eq(expectation), message
      end

      def current_state
        # reload pipeline and all relations
        pipeline.reload

        {
          pipeline: pipeline.status,
          stages: pipeline.stages.pluck(:name, :status).to_h,
          jobs: pipeline.latest_statuses.pluck(:name, :status).to_h
        }
      end

      def process_events(transition)
        if transition['jobs']
          event_on_jobs(transition['event'], transition['jobs'])
        else
          event_on_pipeline(transition['event'])
        end
      end

      def event_on_jobs(event, job_names)
        jobs = pipeline.latest_statuses.by_name(job_names).to_a
        expect(jobs.count).to eq(job_names.count) # ensure that we have the same counts

        jobs.each do |job|
          case event
          when 'play'
            job.play(user)
          when 'retry'
            ::Ci::RetryJobService.new(project, user).execute(job)
          else
            job.public_send("#{event}!")
          end
        end
      end

      def event_on_pipeline(event)
        if event == 'retry'
          pipeline.retry_failed(user)
        else
          pipeline.public_send("#{event}!")
        end
      end
    end
  end

  describe 'Pipeline Processing Service' do
    let(:project) { create(:project, :repository) }
    let(:user)    { project.first_owner }

    let(:pipeline) do
      create(:ci_empty_pipeline, ref: 'master', project: project)
    end

    context 'when simple pipeline is defined' do
      before do
        create_build('linux', stage_idx: 0)
        create_build('mac', stage_idx: 0)
        create_build('rspec', stage_idx: 1)
        create_build('rubocop', stage_idx: 1)
        create_build('deploy', stage_idx: 2)
      end

      it 'processes a pipeline', :sidekiq_inline do
        expect(process_pipeline).to be_truthy

        succeed_pending

        expect(builds.success.count).to eq(2)

        succeed_pending

        expect(builds.success.count).to eq(4)

        succeed_pending

        expect(builds.success.count).to eq(5)
      end

      it 'does not process pipeline if existing stage is running' do
        expect(process_pipeline).to be_truthy
        expect(builds.pending.count).to eq(2)

        expect(process_pipeline).to be_falsey
        expect(builds.pending.count).to eq(2)
      end
    end

    context 'custom stage with first job allowed to fail' do
      before do
        create_build('clean_job', stage_idx: 0, allow_failure: true)
        create_build('test_job', stage_idx: 1, allow_failure: true)
      end

      it 'automatically triggers a next stage when build finishes', :sidekiq_inline do
        expect(process_pipeline).to be_truthy
        expect(builds_statuses).to eq ['pending']

        fail_running_or_pending

        expect(builds_statuses).to eq %w[failed pending]

        fail_running_or_pending

        expect(pipeline.reload).to be_success
      end
    end

    context 'when optional manual actions are defined', :sidekiq_inline do
      before do
        create_build('build', stage_idx: 0)
        create_build('test', stage_idx: 1)
        create_build('test_failure', stage_idx: 2, when: 'on_failure')
        create_build('deploy', stage_idx: 3)
        create_build('production', stage_idx: 3, when: 'manual', allow_failure: true)
        create_build('cleanup', stage_idx: 4, when: 'always')
        create_build('clear:cache', stage_idx: 4, when: 'manual', allow_failure: true)
      end

      context 'when builds are successful' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build']
          expect(builds_statuses).to eq ['pending']

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test deploy production]
          expect(builds_statuses).to eq %w[success success pending manual]

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test deploy production cleanup clear:cache]
          expect(builds_statuses).to eq %w[success success success manual pending manual]

          succeed_running_or_pending

          expect(builds_statuses).to eq %w[success success success manual success manual]
          expect(pipeline.reload.status).to eq 'success'
        end
      end

      context 'when test job fails' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build']
          expect(builds_statuses).to eq ['pending']

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success pending]

          fail_running_or_pending

          expect(builds_names).to eq %w[build test test_failure]
          expect(builds_statuses).to eq %w[success failed pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test test_failure cleanup]
          expect(builds_statuses).to eq %w[success failed success pending]

          succeed_running_or_pending

          expect(builds_statuses).to eq %w[success failed success success]
          expect(pipeline.reload.status).to eq 'failed'
        end
      end

      context 'when test and test_failure jobs fail' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build']
          expect(builds_statuses).to eq ['pending']

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success pending]

          fail_running_or_pending

          expect(builds_names).to eq %w[build test test_failure]
          expect(builds_statuses).to eq %w[success failed pending]

          fail_running_or_pending

          expect(builds_names).to eq %w[build test test_failure cleanup]
          expect(builds_statuses).to eq %w[success failed failed pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test test_failure cleanup]
          expect(builds_statuses).to eq %w[success failed failed success]
          expect(pipeline.reload.status).to eq('failed')
        end
      end

      context 'when deploy job fails' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build']
          expect(builds_statuses).to eq ['pending']

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[build test deploy production]
          expect(builds_statuses).to eq %w[success success pending manual]

          fail_running_or_pending

          expect(builds_names).to eq %w[build test deploy production cleanup]
          expect(builds_statuses).to eq %w[success success failed manual pending]

          succeed_running_or_pending

          expect(builds_statuses).to eq %w[success success failed manual success]
          expect(pipeline.reload).to be_failed
        end
      end

      context 'when build is canceled in the second stage' do
        it 'does not schedule builds after build has been canceled' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build']
          expect(builds_statuses).to eq ['pending']

          succeed_running_or_pending

          expect(builds.running_or_pending).not_to be_empty
          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success pending]

          cancel_running_or_pending

          expect(builds.running_or_pending).to be_empty
          expect(builds_names).to eq %w[build test]
          expect(builds_statuses).to eq %w[success canceled]
          expect(pipeline.reload).to be_canceled
        end
      end

      context 'when listing optional manual actions' do
        it 'returns only for skipped builds' do
          # currently all builds are created
          expect(process_pipeline).to be_truthy
          expect(manual_actions).to be_empty

          # succeed stage build
          succeed_running_or_pending

          expect(manual_actions).to be_empty

          # succeed stage test
          succeed_running_or_pending

          expect(manual_actions).to be_one # production

          # succeed stage deploy
          succeed_running_or_pending

          expect(manual_actions).to be_many # production and clear cache
        end
      end
    end

    context 'when delayed jobs are defined', :sidekiq_inline do
      context 'when the scene is timed incremental rollout' do
        before do
          create_build('build', stage_idx: 0)
          create_build('rollout10%', **delayed_options, stage_idx: 1)
          create_build('rollout100%', **delayed_options, stage_idx: 2)
          create_build('cleanup', stage_idx: 3)

          allow(Ci::BuildScheduleWorker).to receive(:perform_at)
        end

        context 'when builds are successful' do
          it 'properly processes the pipeline' do
            expect(process_pipeline).to be_truthy
            expect(builds_names_and_statuses).to eq({ build: 'pending' })

            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'scheduled' })

            travel_to 2.minutes.from_now do
              enqueue_scheduled('rollout10%')
            end
            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'success', 'rollout100%': 'scheduled' })

            travel_to 2.minutes.from_now do
              enqueue_scheduled('rollout100%')
            end
            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'success', 'rollout100%': 'success', cleanup: 'pending' })

            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'success', 'rollout100%': 'success', cleanup: 'success' })
            expect(pipeline.reload.status).to eq 'success'
          end
        end

        context 'when build job fails' do
          it 'properly processes the pipeline' do
            expect(process_pipeline).to be_truthy
            expect(builds_names_and_statuses).to eq({ build: 'pending' })

            fail_running_or_pending

            expect(builds_names_and_statuses).to eq({ build: 'failed' })
            expect(pipeline.reload.status).to eq 'failed'
          end
        end

        context 'when rollout 10% is unscheduled' do
          it 'properly processes the pipeline' do
            expect(process_pipeline).to be_truthy
            expect(builds_names_and_statuses).to eq({ build: 'pending' })

            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'scheduled' })

            unschedule

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'manual' })
            expect(pipeline.reload.status).to eq 'manual'
          end

          context 'when user plays rollout 10%' do
            it 'schedules rollout100%' do
              process_pipeline
              succeed_pending
              unschedule
              play_manual_action('rollout10%')
              succeed_pending

              expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'success', 'rollout100%': 'scheduled' })
              expect(pipeline.reload.status).to eq 'scheduled'
            end
          end
        end

        context 'when rollout 10% fails' do
          it 'properly processes the pipeline' do
            expect(process_pipeline).to be_truthy
            expect(builds_names_and_statuses).to eq({ build: 'pending' })

            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'scheduled' })

            travel_to 2.minutes.from_now do
              enqueue_scheduled('rollout10%')
            end
            fail_running_or_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'failed' })
            expect(pipeline.reload.status).to eq 'failed'
          end

          context 'when user retries rollout 10%' do
            it 'does not schedule rollout10% again' do
              process_pipeline
              succeed_pending
              enqueue_scheduled('rollout10%')
              fail_running_or_pending
              retry_build('rollout10%')

              expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'pending' })
              expect(pipeline.reload.status).to eq 'running'
            end
          end
        end

        context 'when rollout 10% is played immidiately' do
          it 'properly processes the pipeline' do
            expect(process_pipeline).to be_truthy
            expect(builds_names_and_statuses).to eq({ build: 'pending' })

            succeed_pending

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'scheduled' })

            play_manual_action('rollout10%')

            expect(builds_names_and_statuses).to eq({ build: 'success', 'rollout10%': 'pending' })
            expect(pipeline.reload.status).to eq 'running'
          end
        end
      end

      context 'when only one scheduled job exists in a pipeline' do
        before do
          create_build('delayed', **delayed_options, stage_idx: 0)

          allow(Ci::BuildScheduleWorker).to receive(:perform_at)
        end

        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ delayed: 'scheduled' })

          expect(pipeline.reload.status).to eq 'scheduled'
        end
      end

      context 'when there are two delayed jobs in a stage' do
        before do
          create_build('delayed1', **delayed_options, stage_idx: 0)
          create_build('delayed2', **delayed_options, stage_idx: 0)
          create_build('job', stage_idx: 1)

          allow(Ci::BuildScheduleWorker).to receive(:perform_at)
        end

        it 'blocks the stage until all scheduled jobs finished' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ delayed1: 'scheduled', delayed2: 'scheduled' })

          travel_to 2.minutes.from_now do
            enqueue_scheduled('delayed1')
          end

          expect(builds_names_and_statuses).to eq({ delayed1: 'pending', delayed2: 'scheduled' })
          expect(pipeline.reload.status).to eq 'running'
        end
      end

      context 'when a delayed job is allowed to fail' do
        before do
          create_build('delayed', **delayed_options, allow_failure: true, stage_idx: 0)
          create_build('job', stage_idx: 1)

          allow(Ci::BuildScheduleWorker).to receive(:perform_at)
        end

        it 'blocks the stage and continues after it failed' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ delayed: 'scheduled' })

          travel_to 2.minutes.from_now do
            enqueue_scheduled('delayed')
          end
          fail_running_or_pending

          expect(builds_names_and_statuses).to eq({ delayed: 'failed', job: 'pending' })
          expect(pipeline.reload.status).to eq 'pending'
        end
      end
    end

    context 'when an exception is raised during a persistent ref creation' do
      before do
        successful_build('test', stage_idx: 0)

        allow_next_instance_of(Ci::PersistentRef) do |instance|
          allow(instance).to receive(:delete_refs) { raise ArgumentError }
        end
      end

      it 'process the pipeline' do
        expect { process_pipeline }.not_to raise_error
      end
    end

    context 'when there are manual action in earlier stages' do
      context 'when first stage has only optional manual actions' do
        before do
          create_build('build', stage_idx: 0, when: 'manual', allow_failure: true)
          create_build('check', stage_idx: 1)
          create_build('test', stage_idx: 2)

          process_pipeline
        end

        it 'starts from the second stage' do
          expect(all_builds_statuses).to eq %w[manual pending created]
        end
      end

      context 'when second stage has only optional manual actions' do
        before do
          create_build('check', stage_idx: 0)
          create_build('build', stage_idx: 1, when: 'manual', allow_failure: true)
          create_build('test', stage_idx: 2)

          process_pipeline
        end

        it 'skips second stage and continues on third stage', :sidekiq_inline do
          expect(all_builds_statuses).to eq(%w[pending created created])

          builds.first.success

          expect(all_builds_statuses).to eq(%w[success manual pending])
        end
      end
    end

    context 'when there are only manual actions in stages' do
      before do
        create_build('image', stage_idx: 0, when: 'manual', allow_failure: true)
        create_build('build', stage_idx: 1, when: 'manual', allow_failure: true)
        create_build('deploy', stage_idx: 2, when: 'manual')
        create_build('check', stage_idx: 3)

        process_pipeline
      end

      it 'processes all jobs until blocking actions encountered' do
        expect(all_builds_statuses).to eq(%w[manual manual manual created])
        expect(all_builds_names).to eq(%w[image build deploy check])

        expect(pipeline.reload).to be_blocked
      end
    end

    context 'when there is only one manual action' do
      before do
        create_build('deploy', stage_idx: 0, when: 'manual', allow_failure: true)

        process_pipeline
      end

      it 'skips the pipeline' do
        expect(pipeline.reload).to be_skipped
      end

      context 'when the action was played' do
        before do
          play_manual_action('deploy')
        end

        it 'queues the action and pipeline', :sidekiq_inline do
          expect(all_builds_statuses).to eq(%w[pending])

          expect(pipeline.reload).to be_pending
        end
      end
    end

    context 'when blocking manual actions are defined', :sidekiq_inline do
      before do
        create_build('code:test', stage_idx: 0)
        create_build('staging:deploy', stage_idx: 1, when: 'manual')
        create_build('staging:test', stage_idx: 2, when: 'on_success')
        create_build('production:deploy', stage_idx: 3, when: 'manual')
        create_build('production:test', stage_idx: 4, when: 'always')
      end

      context 'when first stage succeeds' do
        it 'blocks pipeline on stage with first manual action' do
          process_pipeline

          expect(builds_names).to eq %w[code:test]
          expect(builds_statuses).to eq %w[pending]
          expect(pipeline.reload.status).to eq 'pending'

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy]
          expect(builds_statuses).to eq %w[success manual]
          expect(pipeline.reload).to be_manual
        end
      end

      context 'when first stage fails' do
        it 'does not take blocking action into account' do
          process_pipeline

          expect(builds_names).to eq %w[code:test]
          expect(builds_statuses).to eq %w[pending]
          expect(pipeline.reload.status).to eq 'pending'

          fail_running_or_pending

          expect(builds_names).to eq %w[code:test production:test]
          expect(builds_statuses).to eq %w[failed pending]

          succeed_running_or_pending

          expect(builds_statuses).to eq %w[failed success]
          expect(pipeline.reload).to be_failed
        end
      end

      context 'when pipeline is promoted sequentially up to the end' do
        before do
          # Users need ability to merge into a branch in order to trigger
          # protected manual actions.
          #
          create(:protected_branch, :developers_can_merge, name: 'master', project: project)
        end

        it 'properly processes entire pipeline' do
          process_pipeline

          expect(builds_names).to eq %w[code:test]
          expect(builds_statuses).to eq %w[pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy]
          expect(builds_statuses).to eq %w[success manual]
          expect(pipeline.reload).to be_manual

          play_manual_action('staging:deploy')

          expect(builds_statuses).to eq %w[success pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy staging:test]
          expect(builds_statuses).to eq %w[success success pending]

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy staging:test
            production:deploy]
          expect(builds_statuses).to eq %w[success success success manual]

          expect(pipeline.reload).to be_manual
          expect(pipeline.reload).to be_blocked
          expect(pipeline.reload).not_to be_active
          expect(pipeline.reload).not_to be_complete

          play_manual_action('production:deploy')

          expect(builds_statuses).to eq %w[success success success pending]
          expect(pipeline.reload).to be_running

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy staging:test
            production:deploy production:test]
          expect(builds_statuses).to eq %w[success success success success pending]
          expect(pipeline.reload).to be_running

          succeed_running_or_pending

          expect(builds_names).to eq %w[code:test staging:deploy staging:test
            production:deploy production:test]
          expect(builds_statuses).to eq %w[success success success success success]
          expect(pipeline.reload).to be_success
        end
      end
    end

    context 'when second stage has only on_failure jobs', :sidekiq_inline do
      before do
        create_build('check', stage_idx: 0)
        create_build('build', stage_idx: 1, when: 'on_failure')
        create_build('test', stage_idx: 2)

        process_pipeline
      end

      it 'skips second stage and continues on third stage' do
        expect(all_builds_statuses).to eq(%w[pending created created])

        builds.first.success

        expect(all_builds_statuses).to eq(%w[success skipped pending])
      end
    end

    context 'when failed build in the middle stage is retried', :sidekiq_inline do
      context 'when failed build is the only unsuccessful build in the stage' do
        before do
          create_build('build:1', stage_idx: 0)
          create_build('build:2', stage_idx: 0)
          create_build('test:1', stage_idx: 1)
          create_build('test:2', stage_idx: 1)
          create_build('deploy:1', stage_idx: 2)
          create_build('deploy:2', stage_idx: 2)
        end

        it 'does trigger builds in the next stage' do
          expect(process_pipeline).to be_truthy
          expect(builds_names).to eq ['build:1', 'build:2']

          succeed_running_or_pending

          expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2']

          pipeline.builds.find_by(name: 'test:1').success!
          pipeline.builds.find_by(name: 'test:2').drop!

          expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2']

          Ci::RetryJobService.new(pipeline.project, user).execute(pipeline.builds.find_by(name: 'test:2'))[:job].reset.success!

          expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2',
            'test:2', 'deploy:1', 'deploy:2']
        end
      end
    end

    context 'when builds with auto-retries are configured', :sidekiq_inline do
      before do
        create_build('build:1', stage_idx: 0, user: user, options: { script: 'aa', retry: 2 })
        create_build('test:1', stage_idx: 1, user: user, when: :on_failure)
        create_build('test:2', stage_idx: 1, user: user, options: { script: 'aa', retry: 1 })
      end

      it 'automatically retries builds in a valid order' do
        expect(process_pipeline).to be_truthy

        fail_running_or_pending

        expect(builds_names).to eq %w[build:1 build:1]
        expect(builds_statuses).to eq %w[failed pending]

        succeed_running_or_pending

        expect(builds_names).to eq %w[build:1 build:1 test:2]
        expect(builds_statuses).to eq %w[failed success pending]

        succeed_running_or_pending

        expect(builds_names).to eq %w[build:1 build:1 test:2]
        expect(builds_statuses).to eq %w[failed success success]

        expect(pipeline.reload).to be_success
      end
    end

    context 'when pipeline with needs is created', :sidekiq_inline do
      let!(:linux_build) { create_build('linux:build', stage: 'build', stage_idx: 0) }
      let!(:mac_build) { create_build('mac:build', stage: 'build', stage_idx: 0) }
      let!(:linux_rspec) { create_build('linux:rspec', stage: 'test', stage_idx: 1, scheduling_type: :dag) }
      let!(:linux_rubocop) { create_build('linux:rubocop', stage: 'test', stage_idx: 1, scheduling_type: :dag) }
      let!(:mac_rspec) { create_build('mac:rspec', stage: 'test', stage_idx: 1, scheduling_type: :dag) }
      let!(:mac_rubocop) { create_build('mac:rubocop', stage: 'test', stage_idx: 1, scheduling_type: :dag) }
      let!(:deploy) { create_build('deploy', stage: 'deploy', stage_idx: 2) }

      let!(:linux_rspec_on_build) { create(:ci_build_need, build: linux_rspec, name: 'linux:build') }
      let!(:linux_rubocop_on_build) { create(:ci_build_need, build: linux_rubocop, name: 'linux:build') }

      let!(:mac_rspec_on_build) { create(:ci_build_need, build: mac_rspec, name: 'mac:build') }
      let!(:mac_rubocop_on_build) { create(:ci_build_need, build: mac_rubocop, name: 'mac:build') }

      it 'when linux:* finishes first it runs it out of order' do
        expect(process_pipeline).to be_truthy

        expect(stages).to eq(%w[pending created created])
        expect(builds.pending).to contain_exactly(linux_build, mac_build)

        # we follow the single path of linux
        linux_build.reset.success!

        expect(stages).to eq(%w[running pending created])
        expect(builds.success).to contain_exactly(linux_build)
        expect(builds.pending).to contain_exactly(mac_build, linux_rspec, linux_rubocop)

        linux_rspec.reset.success!

        expect(stages).to eq(%w[running running created])
        expect(builds.success).to contain_exactly(linux_build, linux_rspec)
        expect(builds.pending).to contain_exactly(mac_build, linux_rubocop)

        linux_rubocop.reset.success!

        expect(stages).to eq(%w[running running created])
        expect(builds.success).to contain_exactly(linux_build, linux_rspec, linux_rubocop)
        expect(builds.pending).to contain_exactly(mac_build)

        mac_build.reset.success!
        mac_rspec.reset.success!
        mac_rubocop.reset.success!

        expect(stages).to eq(%w[success success pending])
        expect(builds.success).to contain_exactly(
          linux_build, linux_rspec, linux_rubocop, mac_build, mac_rspec, mac_rubocop)
        expect(builds.pending).to contain_exactly(deploy)
      end

      context 'when one of the jobs is run on a failure' do
        let!(:linux_notify) { create_build('linux:notify', stage: 'deploy', stage_idx: 2, when: 'on_failure', scheduling_type: :dag) }

        let!(:linux_notify_on_build) { create(:ci_build_need, build: linux_notify, name: 'linux:build') }

        context 'when another job in build phase fails first' do
          it 'does skip linux:notify' do
            expect(process_pipeline).to be_truthy

            mac_build.reset.drop!
            linux_build.reset.success!

            expect(linux_notify.reset).to be_skipped
          end
        end

        context 'when linux:build job fails first' do
          it 'does run linux:notify' do
            expect(process_pipeline).to be_truthy

            linux_build.reset.drop!

            expect(linux_notify.reset).to be_pending
          end
        end
      end

      context 'when there is a job scheduled with dag but no need (needs: [])' do
        let!(:deploy_pages) { create_build('deploy_pages', stage: 'deploy', stage_idx: 2, scheduling_type: :dag) }

        it 'runs deploy_pages without waiting prior stages' do
          expect(process_pipeline).to be_truthy

          expect(stages).to eq(%w[pending created pending])
          expect(builds.pending).to contain_exactly(linux_build, mac_build, deploy_pages)

          linux_build.reset.success!
          deploy_pages.reset.success!

          expect(stages).to eq(%w[running pending running])
          expect(builds.success).to contain_exactly(linux_build, deploy_pages)
          expect(builds.pending).to contain_exactly(mac_build, linux_rspec, linux_rubocop)

          linux_rspec.reset.success!
          linux_rubocop.reset.success!
          mac_build.reset.success!
          mac_rspec.reset.success!
          mac_rubocop.reset.success!

          expect(stages).to eq(%w[success success running])
          expect(builds.pending).to contain_exactly(deploy)
        end
      end
    end

    context 'when a needed job is skipped', :sidekiq_inline do
      let!(:linux_build) { create_build('linux:build', stage: 'build', stage_idx: 0) }
      let!(:linux_rspec) { create_build('linux:rspec', stage: 'test', stage_idx: 1) }
      let!(:deploy) { create_build('deploy', stage: 'deploy', stage_idx: 2, scheduling_type: :dag) }

      before do
        create(:ci_build_need, build: deploy, name: 'linux:build')
      end

      it 'skips the jobs depending on it' do
        expect(process_pipeline).to be_truthy

        expect(stages).to eq(%w[pending created created])
        expect(all_builds.pending).to contain_exactly(linux_build)

        linux_build.reset.drop!

        expect(stages).to eq(%w[failed skipped skipped])
        expect(all_builds.failed).to contain_exactly(linux_build)
        expect(all_builds.skipped).to contain_exactly(linux_rspec, deploy)
      end
    end

    context 'when a needed job is manual', :sidekiq_inline do
      let!(:linux_build) { create_build('linux:build', stage: 'build', stage_idx: 0, when: 'manual', allow_failure: true) }
      let!(:deploy) { create_build('deploy', stage: 'deploy', stage_idx: 1, scheduling_type: :dag) }

      before do
        create(:ci_build_need, build: deploy, name: 'linux:build')
      end

      it 'makes deploy DAG to be skipped' do
        expect(process_pipeline).to be_truthy

        expect(stages).to eq(%w[skipped skipped])
        expect(all_builds.manual).to contain_exactly(linux_build)
        expect(all_builds.skipped).to contain_exactly(deploy)
      end
    end

    context 'when dependent jobs are listed after job needs in the same stage' do
      let(:config) do
        <<-YAML
        test1:
          stage: test
          needs: [manual1]
          script: exit 0

        test2:
          stage: test
          script: exit 0

        manual1:
          stage: test
          when: manual
          script: exit 0
        YAML
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      let(:statuses) do
        { manual1: 'manual', test1: 'skipped', test2: 'pending' }
      end

      before do
        stub_ci_pipeline_yaml_file(config)
        process_pipeline
      end

      it 'test1 is in skipped state' do
        expect(all_builds_names_and_statuses).to eq(statuses)
        expect(stages).to eq(['pending'])
      end

      context 'with multiple batches' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
        end

        it 'test1 is in skipped state' do
          expect(all_builds_names_and_statuses).to eq(statuses)
          expect(stages).to eq(['pending'])
        end
      end
    end

    context 'when jobs change from stopped to alive status during pipeline processing' do
      around do |example|
        Sidekiq::Testing.fake! { example.run }
      end

      let(:config) do
        <<-YAML
        stages: [test, deploy]

        manual1:
          stage: test
          when: manual
          script: exit 0

        manual2:
          stage: test
          when: manual
          script: exit 0

        test1:
          stage: test
          needs: [manual1]
          script: exit 0

        test2:
          stage: test
          needs: [manual2]
          script: exit 0

        deploy1:
          stage: deploy
          needs: [manual1, manual2]
          script: exit 0

        deploy2:
          stage: deploy
          needs: [test2]
          script: exit 0
        YAML
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      let(:manual1) { all_builds.find_by(name: 'manual1') }
      let(:manual2) { all_builds.find_by(name: 'manual2') }

      let(:statuses_0) do
        { manual1: 'created', manual2: 'created', test1: 'created', test2: 'created', deploy1: 'created', deploy2: 'created' }
      end

      let(:statuses_1) do
        { manual1: 'manual', manual2: 'manual', test1: 'skipped', test2: 'skipped', deploy1: 'skipped', deploy2: 'skipped' }
      end

      let(:statuses_2) do
        { manual1: 'pending', manual2: 'pending', test1: 'skipped', test2: 'skipped', deploy1: 'skipped', deploy2: 'skipped' }
      end

      let(:statuses_3) do
        { manual1: 'pending', manual2: 'pending', test1: 'created', test2: 'created', deploy1: 'created', deploy2: 'created' }
      end

      let(:log_info) do
        {
          class: described_class.name.to_s,
          message: 'Running ResetSkippedJobsService on new alive jobs',
          project_id: project.id,
          pipeline_id: pipeline.id,
          user_id: user.id,
          jobs_count: 2
        }
      end

      before do
        stub_ci_pipeline_yaml_file(config)
        pipeline # Create the pipeline
      end

      # Since this is a test for a race condition, we are calling internal method `enqueue!`
      # instead of `play` and stubbing `new_alive_jobs` of the service class.
      it 'runs ResetSkippedJobsService on the new alive jobs and logs event' do
        # Initial control without any pipeline processing
        expect(all_builds_names_and_statuses).to eq(statuses_0)

        process_pipeline

        # Initial control after the first pipeline processing
        expect(all_builds_names_and_statuses).to eq(statuses_1)

        # Change the manual jobs from stopped to alive status.
        # We don't use `play` to avoid running `ResetSkippedJobsService`.
        manual1.enqueue!
        manual2.enqueue!

        # Statuses after playing the manual jobs
        expect(all_builds_names_and_statuses).to eq(statuses_2)

        mock_play_jobs_during_processing([manual1, manual2])

        expect(Ci::ResetSkippedJobsService).to receive(:new).once.and_call_original

        process_pipeline

        expect(all_builds_names_and_statuses).to eq(statuses_3)
      end

      it 'logs event' do
        expect(Gitlab::AppJsonLogger).to receive(:info).once.with(log_info)

        mock_play_jobs_during_processing([manual1, manual2])
        process_pipeline
      end

      context 'when the new alive jobs belong to different users' do
        let_it_be(:user2) { create(:user) }

        before do
          process_pipeline # First pipeline processing

          # Change the manual jobs from stopped to alive status
          manual1.enqueue!
          manual2.enqueue!

          manual2.update!(user: user2)

          mock_play_jobs_during_processing([manual1, manual2])
        end

        it 'runs ResetSkippedJobsService on the new alive jobs' do
          # Statuses after playing the manual jobs
          expect(all_builds_names_and_statuses).to eq(statuses_2)

          # Since there are two different users, we expect this service to be called twice.
          expect(Ci::ResetSkippedJobsService).to receive(:new).twice.and_call_original

          process_pipeline

          expect(all_builds_names_and_statuses).to eq(statuses_3)
        end

        # In this scenario, the new alive jobs (manual1 and manual2) have different users.
        # We can only know for certain the assigned user of dependent jobs that are exclusive
        # to either manual1 or manual2. Otherwise, the assigned user will depend on which of
        # the new alive jobs get processed first by ResetSkippedJobsService.
        it 'assigns the correct user to the dependent jobs' do
          test1 = all_builds.find_by(name: 'test1')
          test2 = all_builds.find_by(name: 'test2')

          expect(test1.user).to eq(user)
          expect(test2.user).to eq(user)

          process_pipeline

          expect(test1.reset.user).to eq(user)
          expect(test2.reset.user).to eq(user2)
        end

        it 'logs event' do
          expect(Gitlab::AppJsonLogger).to receive(:info).once.with(log_info.merge(jobs_count: 1))
          expect(Gitlab::AppJsonLogger).to receive(:info).once.with(log_info.merge(user_id: user2.id, jobs_count: 1))

          mock_play_jobs_during_processing([manual1, manual2])
          process_pipeline
        end
      end
    end

    context 'when a bridge job has parallel:matrix config', :sidekiq_inline do
      let(:parent_config) do
        <<-EOY
        test:
          stage: test
          script: echo test

        deploy:
          stage: deploy
          trigger:
            include: .child.yml
          parallel:
            matrix:
              - PROVIDER: ovh
                STACK: [monitoring, app]
        EOY
      end

      let(:child_config) do
        <<-EOY
        test:
          stage: test
          script: echo test
        EOY
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      let(:project_files) do
        {
          '.gitlab-ci.yml' => parent_config,
          '.child.yml' => child_config
        }
      end

      around do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it 'creates pipeline with bridges, then passes the matrix variables to downstream jobs' do
        expect(all_builds_names).to contain_exactly('test', 'deploy: [ovh, monitoring]', 'deploy: [ovh, app]')
        expect(all_builds_statuses).to contain_exactly('pending', 'created', 'created')

        succeed_pending

        # bridge jobs directly transition to success
        expect(all_builds_statuses).to contain_exactly('success', 'success', 'success')

        bridge1 = all_builds.find_by(name: 'deploy: [ovh, monitoring]')
        bridge2 = all_builds.find_by(name: 'deploy: [ovh, app]')

        downstream_job1 = bridge1.downstream_pipeline.all_jobs.first
        downstream_job2 = bridge2.downstream_pipeline.all_jobs.first

        expect(downstream_job1.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'monitoring')
        expect(downstream_job2.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'app')
      end
    end

    context 'when a bridge job has invalid downstream project', :sidekiq_inline do
      let(:config) do
        <<-EOY
        test:
          stage: test
          script: echo test

        deploy:
          stage: deploy
          trigger:
            project: invalid-project
        EOY
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline, then fails the bridge job' do
        expect(all_builds_names).to contain_exactly('test', 'deploy')
        expect(all_builds_statuses).to contain_exactly('pending', 'created')

        succeed_pending

        expect(all_builds_names).to contain_exactly('test', 'deploy')
        expect(all_builds_statuses).to contain_exactly('success', 'failed')
      end
    end

    context 'when the dependency is stage-independent', :sidekiq_inline do
      let(:config) do
        <<-EOY
        stages: [A, B]

        A1:
          stage: A
          script: exit 0
          when: manual

        A2:
          stage: A
          script: exit 0
          needs: [A1]

        B:
          stage: B
          needs: [A2]
          script: exit 0
        EOY
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'processes subsequent jobs in the correct order when playing first job' do
        expect(all_builds_names).to eq(%w[A1 A2 B])
        expect(all_builds_statuses).to eq(%w[manual skipped skipped])

        play_manual_action('A1')

        expect(all_builds_names).to eq(%w[A1 A2 B])
        expect(all_builds_statuses).to eq(%w[pending created created])
      end
    end

    context 'when the exclusive lease is taken' do
      let(:lease_key) { "ci/pipeline_processing/atomic_processing_service::pipeline_id:#{pipeline.id}" }

      it 'skips pipeline processing' do
        create_build('linux', stage_idx: 0)

        stub_exclusive_lease_taken(lease_key)

        expect(Gitlab::AppJsonLogger).to receive(:info).with(a_hash_including(message: /^Cannot obtain an exclusive lease/))
        expect(process_pipeline).to be_falsy
      end
    end

    describe 'deployments creation' do
      let(:config) do
        <<-YAML
        stages: [stage-0, stage-1, stage-2, stage-3, stage-4]

        test:
          stage: stage-0
          script: exit 0

        review:
          stage: stage-1
          environment:
            name: review
            action: start
          script: exit 0

        staging:
          stage: stage-2
          environment:
            name: staging
            action: start
          script: exit 0
          when: manual
          allow_failure: false

        canary:
          stage: stage-3
          environment:
            name: canary
            action: start
          script: exit 0
          when: manual

        production-a:
          stage: stage-4
          environment:
            name: production-a
            action: start
          script: exit 0
          when: manual

        production-b:
          stage: stage-4
          environment:
            name: production-b
            action: start
          script: exit 0
          when: manual
          needs: [canary]
        YAML
      end

      let(:pipeline) do
        Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
      end

      let(:test_job) { all_builds.find_by(name: 'test') }
      let(:review_deploy_job) { all_builds.find_by(name: 'review') }
      let(:staging_deploy_job) { all_builds.find_by(name: 'staging') }
      let(:canary_deploy_job) { all_builds.find_by(name: 'canary') }
      let(:production_a_deploy_job) { all_builds.find_by(name: 'production-a') }
      let(:production_b_deploy_job) { all_builds.find_by(name: 'production-b') }

      before do
        create(:environment, name: 'review', project: project)
        create(:environment, name: 'staging', project: project)
        create(:environment, name: 'canary', project: project)
        create(:environment, name: 'production-a', project: project)
        create(:environment, name: 'production-b', project: project)

        stub_ci_pipeline_yaml_file(config)
        pipeline # create the pipeline
      end

      it 'creates deployment records for the deploy jobs', :aggregate_failures do
        # processes the 'test' job, not creating a Deployment record
        expect { process_pipeline }.not_to change { Deployment.count }
        succeed_pending
        expect(test_job.status).to eq 'success'

        # processes automatic 'review' deploy job, creating a Deployment record
        expect { process_pipeline }.to change { Deployment.count }.by(1)
        succeed_pending
        expect(review_deploy_job.status).to eq 'success'

        # processes manual 'staging' deploy job, creating a Deployment record
        # the subsequent manual deploy jobs ('canary', 'production-a', 'production-b')
        #   are not yet processed because 'staging' is set as `allow_failure: false`
        expect { process_pipeline }.to change { Deployment.count }.by(1)
        play_manual_action('staging')
        succeed_pending
        expect(staging_deploy_job.reload.status).to eq 'success'

        # processes manual 'canary' deployment job
        # the subsequent manual deploy jobs ('production-a' and 'production-b')
        #   are also processed because 'canary' is set by default as `allow_failure: true`
        #   the 'production-b' is set as `needs: [canary]`, but it is still processed
        # overall, 3 Deployment records are created
        expect { process_pipeline }.to change { Deployment.count }.by(3)
        expect(canary_deploy_job.status).to eq 'manual'
        expect(production_a_deploy_job.status).to eq 'manual'
        expect(production_b_deploy_job.status).to eq 'skipped'

        # play and succeed the manual 'canary' and 'production-a' jobs
        play_manual_action('canary')
        play_manual_action('production-a')
        succeed_pending
        expect(canary_deploy_job.reload.status).to eq 'success'
        expect(production_a_deploy_job.reload.status).to eq 'success'
        expect(production_b_deploy_job.reload.status).to eq 'created'

        # process the manual 'production-b' job again, no Deployment record is created
        #   because it has already been created when 'production-b' was first processed
        expect { process_pipeline }.not_to change { Deployment.count }
        expect(production_b_deploy_job.reload.status).to eq 'manual'
      end
    end

    private

    def all_builds
      pipeline.all_jobs.order(:stage_idx, :id)
    end

    def builds
      all_builds.where.not(status: [:created, :skipped])
    end

    def stages
      pipeline.reset.stages.map(&:status)
    end

    def builds_names
      builds.pluck(:name)
    end

    def builds_names_and_statuses
      builds.each_with_object({}) do |b, h|
        h[b.name.to_sym] = b.status
      end
    end

    def all_builds_names_and_statuses
      all_builds.each_with_object({}) do |b, h|
        h[b.name.to_sym] = b.status
      end
    end

    def all_builds_names
      all_builds.pluck(:name)
    end

    def builds_statuses
      builds.pluck(:status)
    end

    def all_builds_statuses
      all_builds.pluck(:status)
    end

    def succeed_pending
      builds.pending.each do |build|
        build.reset.success
      end
    end

    def succeed_running_or_pending
      pipeline.builds.running_or_pending.each do |build|
        build.reset.success
      end
    end

    def fail_running_or_pending
      pipeline.builds.running_or_pending.each do |build|
        build.reset.drop
      end
    end

    def cancel_running_or_pending
      pipeline.builds.running_or_pending.each do |build|
        build.reset.cancel
      end
    end

    def play_manual_action(name)
      builds.find_by(name: name).play(user)
    end

    def enqueue_scheduled(name)
      builds.scheduled.find_by(name: name).enqueue!
    end

    def retry_build(name)
      Ci::RetryJobService.new(project, user).execute(builds.find_by(name: name))
    end

    def manual_actions
      pipeline.manual_actions.reload
    end

    def create_build(name, **opts)
      create(:ci_build, :created, pipeline: pipeline, name: name, **with_stage_opts(opts))
    end

    def successful_build(name, **opts)
      create(:ci_build, :success, pipeline: pipeline, name: name, **with_stage_opts(opts))
    end

    def with_stage_opts(opts)
      { stage: "stage-#{opts[:stage_idx].to_i}" }.merge(opts)
    end

    def delayed_options
      { when: 'delayed', options: { script: %w[echo], start_in: '1 minute' } }
    end

    def unschedule
      pipeline.builds.scheduled.map(&:unschedule)
    end
  end

  private

  def process_pipeline
    described_class.new(pipeline).execute
  end

  # A status collection is initialized at the start of pipeline processing and then again at the
  # end of processing.  Here we simulate "playing" the given jobs during pipeline processing by
  # stubbing stopped_job_names so that they appear to have been stopped at the beginning of
  # processing and then later changed to alive status at the end.
  def mock_play_jobs_during_processing(jobs)
    collection = Ci::PipelineProcessing::AtomicProcessingService::StatusCollection.new(pipeline)

    allow(collection).to receive(:stopped_job_names).and_return(jobs.map(&:name), [])

    # Return the same collection object for every instance of StatusCollection
    allow(Ci::PipelineProcessing::AtomicProcessingService::StatusCollection).to receive(:new)
      .and_return(collection)
  end
end
