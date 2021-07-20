# frozen_string_literal: true

RSpec.shared_examples 'Pipeline Processing Service' do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }

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

      expect(builds_statuses).to eq %w(failed pending)

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

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy production)
        expect(builds_statuses).to eq %w(success success pending manual)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy production cleanup clear:cache)
        expect(builds_statuses).to eq %w(success success success manual pending manual)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success success success manual success manual)
        expect(pipeline.reload.status).to eq 'success'
      end
    end

    context 'when test job fails' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure)
        expect(builds_statuses).to eq %w(success failed pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed success pending)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success failed success success)
        expect(pipeline.reload.status).to eq 'failed'
      end
    end

    context 'when test and test_failure jobs fail' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure)
        expect(builds_statuses).to eq %w(success failed pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed failed pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed failed success)
        expect(pipeline.reload.status).to eq('failed')
      end
    end

    context 'when deploy job fails' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy production)
        expect(builds_statuses).to eq %w(success success pending manual)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test deploy production cleanup)
        expect(builds_statuses).to eq %w(success success failed manual pending)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success success failed manual success)
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
        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

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
          expect(builds_names_and_statuses).to eq({ 'build': 'pending' })

          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'scheduled' })

          travel_to 2.minutes.from_now do
            enqueue_scheduled('rollout10%')
          end
          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'success', 'rollout100%': 'scheduled' })

          travel_to 2.minutes.from_now do
            enqueue_scheduled('rollout100%')
          end
          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'success', 'rollout100%': 'success', 'cleanup': 'pending' })

          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'success', 'rollout100%': 'success', 'cleanup': 'success' })
          expect(pipeline.reload.status).to eq 'success'
        end
      end

      context 'when build job fails' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ 'build': 'pending' })

          fail_running_or_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'failed' })
          expect(pipeline.reload.status).to eq 'failed'
        end
      end

      context 'when rollout 10% is unscheduled' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ 'build': 'pending' })

          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'scheduled' })

          unschedule

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'manual' })
          expect(pipeline.reload.status).to eq 'manual'
        end

        context 'when user plays rollout 10%' do
          it 'schedules rollout100%' do
            process_pipeline
            succeed_pending
            unschedule
            play_manual_action('rollout10%')
            succeed_pending

            expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'success', 'rollout100%': 'scheduled' })
            expect(pipeline.reload.status).to eq 'scheduled'
          end
        end
      end

      context 'when rollout 10% fails' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ 'build': 'pending' })

          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'scheduled' })

          travel_to 2.minutes.from_now do
            enqueue_scheduled('rollout10%')
          end
          fail_running_or_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'failed' })
          expect(pipeline.reload.status).to eq 'failed'
        end

        context 'when user retries rollout 10%' do
          it 'does not schedule rollout10% again' do
            process_pipeline
            succeed_pending
            enqueue_scheduled('rollout10%')
            fail_running_or_pending
            retry_build('rollout10%')

            expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'pending' })
            expect(pipeline.reload.status).to eq 'running'
          end
        end
      end

      context 'when rollout 10% is played immidiately' do
        it 'properly processes the pipeline' do
          expect(process_pipeline).to be_truthy
          expect(builds_names_and_statuses).to eq({ 'build': 'pending' })

          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'scheduled' })

          play_manual_action('rollout10%')

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'pending' })
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
        expect(builds_names_and_statuses).to eq({ 'delayed': 'scheduled' })

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
        expect(builds_names_and_statuses).to eq({ 'delayed1': 'scheduled', 'delayed2': 'scheduled' })

        travel_to 2.minutes.from_now do
          enqueue_scheduled('delayed1')
        end

        expect(builds_names_and_statuses).to eq({ 'delayed1': 'pending', 'delayed2': 'scheduled' })
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
        expect(builds_names_and_statuses).to eq({ 'delayed': 'scheduled' })

        travel_to 2.minutes.from_now do
          enqueue_scheduled('delayed')
        end
        fail_running_or_pending

        expect(builds_names_and_statuses).to eq({ 'delayed': 'failed', 'job': 'pending' })
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
        create(:protected_branch, :developers_can_merge,
                name: 'master', project: project)
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

        Ci::Build.retry(pipeline.builds.find_by(name: 'test:2'), user).reset.success!

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

      expect(stages).to eq(%w(pending created created))
      expect(builds.pending).to contain_exactly(linux_build, mac_build)

      # we follow the single path of linux
      linux_build.reset.success!

      expect(stages).to eq(%w(running pending created))
      expect(builds.success).to contain_exactly(linux_build)
      expect(builds.pending).to contain_exactly(mac_build, linux_rspec, linux_rubocop)

      linux_rspec.reset.success!

      expect(stages).to eq(%w(running running created))
      expect(builds.success).to contain_exactly(linux_build, linux_rspec)
      expect(builds.pending).to contain_exactly(mac_build, linux_rubocop)

      linux_rubocop.reset.success!

      expect(stages).to eq(%w(running running created))
      expect(builds.success).to contain_exactly(linux_build, linux_rspec, linux_rubocop)
      expect(builds.pending).to contain_exactly(mac_build)

      mac_build.reset.success!
      mac_rspec.reset.success!
      mac_rubocop.reset.success!

      expect(stages).to eq(%w(success success pending))
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

        expect(stages).to eq(%w(pending created pending))
        expect(builds.pending).to contain_exactly(linux_build, mac_build, deploy_pages)

        linux_build.reset.success!
        deploy_pages.reset.success!

        expect(stages).to eq(%w(running pending running))
        expect(builds.success).to contain_exactly(linux_build, deploy_pages)
        expect(builds.pending).to contain_exactly(mac_build, linux_rspec, linux_rubocop)

        linux_rspec.reset.success!
        linux_rubocop.reset.success!
        mac_build.reset.success!
        mac_rspec.reset.success!
        mac_rubocop.reset.success!

        expect(stages).to eq(%w(success success running))
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

      expect(stages).to eq(%w(pending created created))
      expect(all_builds.pending).to contain_exactly(linux_build)

      linux_build.reset.drop!

      expect(stages).to eq(%w(failed skipped skipped))
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

      expect(stages).to eq(%w(skipped skipped))
      expect(all_builds.manual).to contain_exactly(linux_build)
      expect(all_builds.skipped).to contain_exactly(deploy)
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

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository)
          .to receive(:blob_data_at)
          .with(an_instance_of(String), '.gitlab-ci.yml')
          .and_return(parent_config)

        allow(repository)
          .to receive(:blob_data_at)
          .with(an_instance_of(String), '.child.yml')
          .and_return(child_config)
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

      downstream_job1 = bridge1.downstream_pipeline.processables.first
      downstream_job2 = bridge2.downstream_pipeline.processables.first

      expect(downstream_job1.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'monitoring')
      expect(downstream_job2.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'app')
    end
  end

  private

  def all_builds
    pipeline.processables.order(:stage_idx, :id)
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
      h
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
    builds.scheduled.find_by(name: name).enqueue_scheduled
  end

  def retry_build(name)
    Ci::Build.retry(builds.find_by(name: name), user)
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
    { when: 'delayed', options: { script: %w(echo), start_in: '1 minute' } }
  end

  def unschedule
    pipeline.builds.scheduled.map(&:unschedule)
  end
end
