# frozen_string_literal: true

require 'spec_helper'

describe Ci::ProcessPipelineService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  before do
    stub_ci_pipeline_to_return_yaml_file

    stub_not_protect_default_branch

    project.add_developer(user)
  end

  context 'when simple pipeline is defined' do
    before do
      create_build('linux', stage_idx: 0)
      create_build('mac', stage_idx: 0)
      create_build('rspec', stage_idx: 1)
      create_build('rubocop', stage_idx: 1)
      create_build('deploy', stage_idx: 2)
    end

    it 'processes a pipeline' do
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

    it 'automatically triggers a next stage when build finishes' do
      expect(process_pipeline).to be_truthy
      expect(builds_statuses).to eq ['pending']

      fail_running_or_pending

      expect(builds_statuses).to eq %w(failed pending)

      fail_running_or_pending

      expect(pipeline.reload).to be_success
    end
  end

  context 'when optional manual actions are defined' do
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

  context 'when delayed jobs are defined' do
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

          enqueue_scheduled('rollout10%')
          succeed_pending

          expect(builds_names_and_statuses).to eq({ 'build': 'success', 'rollout10%': 'success', 'rollout100%': 'scheduled' })

          enqueue_scheduled('rollout100%')
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

          enqueue_scheduled('rollout10%')
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

        enqueue_scheduled('delayed1')

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

        enqueue_scheduled('delayed')
        fail_running_or_pending

        expect(builds_names_and_statuses).to eq({ 'delayed': 'failed', 'job': 'pending' })
        expect(pipeline.reload.status).to eq 'pending'
      end
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

      it 'skips second stage and continues on third stage' do
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

      it 'queues the action and pipeline' do
        expect(all_builds_statuses).to eq(%w[pending])

        expect(pipeline.reload).to be_pending
      end
    end
  end

  context 'when blocking manual actions are defined' do
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

  context 'when second stage has only on_failure jobs' do
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

  context 'when failed build in the middle stage is retried' do
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

        pipeline.builds.find_by(name: 'test:1').success
        pipeline.builds.find_by(name: 'test:2').drop

        expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2']

        Ci::Build.retry(pipeline.builds.find_by(name: 'test:2'), user).success

        expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2',
                                    'test:2', 'deploy:1', 'deploy:2']
      end
    end
  end

  context 'updates a list of retried builds' do
    subject { described_class.retried.order(:id) }

    let!(:build_retried) { create_build('build') }
    let!(:build) { create_build('build') }
    let!(:test) { create_build('test') }

    it 'returns unique statuses' do
      process_pipeline

      expect(all_builds.latest).to contain_exactly(build, test)
      expect(all_builds.retried).to contain_exactly(build_retried)
    end
  end

  context 'when builds with auto-retries are configured' do
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

  context 'when pipeline with needs is created' do
    let!(:linux_build) { create_build('linux:build', stage: 'build', stage_idx: 0) }
    let!(:mac_build) { create_build('mac:build', stage: 'build', stage_idx: 0) }
    let!(:linux_rspec) { create_build('linux:rspec', stage: 'test', stage_idx: 1) }
    let!(:linux_rubocop) { create_build('linux:rubocop', stage: 'test', stage_idx: 1) }
    let!(:mac_rspec) { create_build('mac:rspec', stage: 'test', stage_idx: 1) }
    let!(:mac_rubocop) { create_build('mac:rubocop', stage: 'test', stage_idx: 1) }
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

    context 'when feature ci_dag_support is disabled' do
      before do
        stub_feature_flags(ci_dag_support: false)
      end

      it 'when linux:build finishes first it follows stages' do
        expect(process_pipeline).to be_truthy

        expect(stages).to eq(%w(pending created created))
        expect(builds.pending).to contain_exactly(linux_build, mac_build)

        # we follow the single path of linux
        linux_build.reset.success!

        expect(stages).to eq(%w(running created created))
        expect(builds.success).to contain_exactly(linux_build)
        expect(builds.pending).to contain_exactly(mac_build)

        mac_build.reset.success!

        expect(stages).to eq(%w(success pending created))
        expect(builds.success).to contain_exactly(linux_build, mac_build)
        expect(builds.pending).to contain_exactly(
          linux_rspec, linux_rubocop, mac_rspec, mac_rubocop)

        linux_rspec.reset.success!
        linux_rubocop.reset.success!
        mac_rspec.reset.success!
        mac_rubocop.reset.success!

        expect(stages).to eq(%w(success success pending))
        expect(builds.success).to contain_exactly(
          linux_build, linux_rspec, linux_rubocop, mac_build, mac_rspec, mac_rubocop)
        expect(builds.pending).to contain_exactly(deploy)
      end
    end
  end

  def process_pipeline
    described_class.new(pipeline.project, user).execute(pipeline)
  end

  def all_builds
    pipeline.builds.order(:stage_idx, :id)
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
    builds.pending.map(&:success)
  end

  def succeed_running_or_pending
    pipeline.builds.running_or_pending.each(&:success)
  end

  def fail_running_or_pending
    pipeline.builds.running_or_pending.each(&:drop)
  end

  def cancel_running_or_pending
    pipeline.builds.running_or_pending.each(&:cancel)
  end

  def play_manual_action(name)
    builds.find_by(name: name).play(user)
  end

  def enqueue_scheduled(name)
    builds.scheduled.find_by(name: name).enqueue
  end

  def retry_build(name)
    Ci::Build.retry(builds.find_by(name: name), user)
  end

  def manual_actions
    pipeline.manual_actions.reload
  end

  def create_build(name, **opts)
    create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
  end

  def delayed_options
    { when: 'delayed', options: { script: %w(echo), start_in: '1 minute' } }
  end

  def unschedule
    pipeline.builds.scheduled.map(&:unschedule)
  end
end
