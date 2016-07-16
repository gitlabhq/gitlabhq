require 'spec_helper'

describe Ci::ProcessPipelineService, services: true do
  let(:pipeline) { create(:ci_pipeline, ref: 'master') }
  let(:user) { create(:user) }
  let(:builds) { pipeline.builds.where.not(status: [:created, :skipped]) }

  describe '#execute' do
    # Using stubbed .gitlab-ci.yml created in commit factory
    #

    def create_builds
      described_class.new(pipeline.project, user).execute(pipeline)
    end

    def succeed_pending
      builds.pending.update_all(status: 'success')
    end

    context 'start queuing next builds' do
      before do
        create(:ci_build, pipeline: pipeline, name: 'linux', stage_idx: 0)
        create(:ci_build, pipeline: pipeline, name: 'mac', stage_idx: 0)
        create(:ci_build, pipeline: pipeline, name: 'rspec', stage_idx: 1)
        create(:ci_build, pipeline: pipeline, name: 'rubocop', stage_idx: 1)
        create(:ci_build, pipeline: pipeline, name: 'deploy', stage_idx: 2)
      end

      it 'processes a pipeline' do
        expect(create_builds).to be_truthy
        succeed_pending
        expect(builds.success.count).to eq(2)

        expect(create_builds).to be_truthy
        succeed_pending
        expect(builds.success.count).to eq(4)

        expect(create_builds).to be_truthy
        succeed_pending
        expect(builds.success.count).to eq(5)

        expect(create_builds).to be_falsey
      end

      it 'does not process pipeline if existing stage is running' do
        expect(create_builds).to be_truthy
        expect(builds.pending.count).to eq(2)
        
        expect(create_builds).to be_falsey
        expect(builds.pending.count).to eq(2)
      end
    end

    context 'custom stage with first job allowed to fail' do
      before do
        create(:ci_build, pipeline: pipeline, name: 'clean_job', stage_idx: 0, allow_failure: true)
        create(:ci_build, pipeline: pipeline, name: 'test_job', stage_idx: 1, allow_failure: true)
      end

      it 'automatically triggers a next stage when build finishes' do
        expect(create_builds).to be_truthy
        expect(builds.pluck(:status)).to contain_exactly('pending')

        pipeline.builds.running_or_pending.each(&:drop)
        expect(builds.pluck(:status)).to contain_exactly('failed', 'pending')
      end
    end

    context 'properly creates builds when "when" is defined' do
      before do
        create(:ci_build, pipeline: pipeline, name: 'build', stage_idx: 0)
        create(:ci_build, pipeline: pipeline, name: 'test', stage_idx: 1)
        create(:ci_build, pipeline: pipeline, name: 'test_failure', stage_idx: 2, when: 'on_failure')
        create(:ci_build, pipeline: pipeline, name: 'deploy', stage_idx: 3)
        create(:ci_build, pipeline: pipeline, name: 'cleanup', stage_idx: 4, when: 'always')
      end

      context 'when builds are successful' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(builds.pluck(:name)).to contain_exactly('build')
          expect(builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('success')
        end
      end

      context 'when test job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(builds.pluck(:name)).to contain_exactly('build')
          expect(builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when test and test_failure jobs fail' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(builds.pluck(:name)).to contain_exactly('build')
          expect(builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when deploy job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(builds.pluck(:name)).to contain_exactly('build')
          expect(builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when build is canceled in the second stage' do
        it 'does not schedule builds after build has been canceled' do
          expect(create_builds).to be_truthy
          expect(builds.pluck(:name)).to contain_exactly('build')
          expect(builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(builds.running_or_pending).not_to be_empty

          expect(builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:cancel)

          expect(builds.running_or_pending).to be_empty
          expect(pipeline.reload.status).to eq('canceled')
        end
      end
    end
  end
end
