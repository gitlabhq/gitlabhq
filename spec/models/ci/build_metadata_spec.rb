require 'spec_helper'

describe Ci::BuildMetadata do
  set(:user) { create(:user) }
  set(:group) { create(:group, :access_requestable) }
  set(:project) { create(:project, :repository, group: group, build_timeout: 2000) }

  set(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:build_metadata) { described_class.create(build: build) }

  context 'when creating' do
    subject { build_metadata.project_id }

    it 'saves project_id' do
      is_expected.to eq(project.id)
    end
  end

  describe '#save_timeout_state!' do
    subject { build_metadata }

    context 'when runner is not assigned to the job' do
      it "doesn't change timeout value" do
        expect { subject.save_timeout_state! }.not_to change { subject.reload.timeout }
      end

      it "doesn't change timeout_source value" do
        expect { subject.save_timeout_state! }.not_to change { subject.reload.timeout_source }
      end
    end

    context 'when runner is assigned to the job' do
      before do
        build.update_attributes(runner: runner)
      end

      context 'when runner timeout is lower than project timeout' do
        let(:runner) { create(:ci_runner, maximum_timeout: 1900) }

        it 'sets runner timeout' do
          expect { subject.save_timeout_state! }.to change { subject.reload.timeout }.to(1900)
        end

        it 'sets runner_timeout_source' do
          expect { subject.save_timeout_state! }.to change { subject.reload.timeout_source }.to('runner_timeout_source')
        end
      end

      context 'when runner timeout is higher than project timeout' do
        let(:runner) { create(:ci_runner, maximum_timeout: 2100) }

        it 'sets project timeout' do
          expect { subject.save_timeout_state! }.to change { subject.reload.timeout }.to(2000)
        end

        it 'sets project_timeout_source' do
          expect { subject.save_timeout_state! }.to change { subject.reload.timeout_source }.to('project_timeout_source')
        end
      end
    end
  end
end
