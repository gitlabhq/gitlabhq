require 'spec_helper'

module Ci
  describe RegisterJobService do
    let!(:project) { FactoryBot.create :project, shared_runners_enabled: false }
    let!(:pipeline) { FactoryBot.create :ci_pipeline, project: project }
    let!(:pending_job) { FactoryBot.create :ci_build, pipeline: pipeline }
    let!(:shared_runner) { FactoryBot.create(:ci_runner, is_shared: true) }
    let!(:specific_runner) { FactoryBot.create(:ci_runner, is_shared: false) }

    before do
      specific_runner.assign_to(project)
    end

    describe '#execute' do
      context 'runner follow tag list' do
        it "picks build with the same tag" do
          pending_job.update(tag_list: ["linux"])
          specific_runner.update(tag_list: ["linux"])
          expect(execute(specific_runner)).to eq(pending_job)
        end

        it "does not pick build with different tag" do
          pending_job.update(tag_list: ["linux"])
          specific_runner.update(tag_list: ["win32"])
          expect(execute(specific_runner)).to be_falsey
        end

        it "picks build without tag" do
          expect(execute(specific_runner)).to eq(pending_job)
        end

        it "does not pick build with tag" do
          pending_job.update(tag_list: ["linux"])
          expect(execute(specific_runner)).to be_falsey
        end

        it "pick build without tag" do
          specific_runner.update(tag_list: ["win32"])
          expect(execute(specific_runner)).to eq(pending_job)
        end
      end

      context 'deleted projects' do
        before do
          project.update(pending_delete: true)
        end

        context 'for shared runners' do
          before do
            project.update(shared_runners_enabled: true)
          end

          it 'does not pick a build' do
            expect(execute(shared_runner)).to be_nil
          end
        end

        context 'for specific runner' do
          it 'does not pick a build' do
            expect(execute(specific_runner)).to be_nil
          end
        end
      end

      context 'allow shared runners' do
        before do
          project.update(shared_runners_enabled: true)
        end

        context 'for multiple builds' do
          let!(:project2) { create :project, shared_runners_enabled: true }
          let!(:pipeline2) { create :ci_pipeline, project: project2 }
          let!(:project3) { create :project, shared_runners_enabled: true }
          let!(:pipeline3) { create :ci_pipeline, project: project3 }
          let!(:build1_project1) { pending_job }
          let!(:build2_project1) { FactoryBot.create :ci_build, pipeline: pipeline }
          let!(:build3_project1) { FactoryBot.create :ci_build, pipeline: pipeline }
          let!(:build1_project2) { FactoryBot.create :ci_build, pipeline: pipeline2 }
          let!(:build2_project2) { FactoryBot.create :ci_build, pipeline: pipeline2 }
          let!(:build1_project3) { FactoryBot.create :ci_build, pipeline: pipeline3 }

          it 'prefers projects without builds first' do
            # it gets for one build from each of the projects
            expect(execute(shared_runner)).to eq(build1_project1)
            expect(execute(shared_runner)).to eq(build1_project2)
            expect(execute(shared_runner)).to eq(build1_project3)

            # then it gets a second build from each of the projects
            expect(execute(shared_runner)).to eq(build2_project1)
            expect(execute(shared_runner)).to eq(build2_project2)

            # in the end the third build
            expect(execute(shared_runner)).to eq(build3_project1)
          end

          it 'equalises number of running builds' do
            # after finishing the first build for project 1, get a second build from the same project
            expect(execute(shared_runner)).to eq(build1_project1)
            build1_project1.reload.success
            expect(execute(shared_runner)).to eq(build2_project1)

            expect(execute(shared_runner)).to eq(build1_project2)
            build1_project2.reload.success
            expect(execute(shared_runner)).to eq(build2_project2)
            expect(execute(shared_runner)).to eq(build1_project3)
            expect(execute(shared_runner)).to eq(build3_project1)
          end
        end

        context 'shared runner' do
          let(:build) { execute(shared_runner) }

          it { expect(build).to be_kind_of(Build) }
          it { expect(build).to be_valid }
          it { expect(build).to be_running }
          it { expect(build.runner).to eq(shared_runner) }
        end

        context 'specific runner' do
          let(:build) { execute(specific_runner) }

          it { expect(build).to be_kind_of(Build) }
          it { expect(build).to be_valid }
          it { expect(build).to be_running }
          it { expect(build.runner).to eq(specific_runner) }
        end
      end

      context 'disallow shared runners' do
        before do
          project.update(shared_runners_enabled: false)
        end

        context 'shared runner' do
          let(:build) { execute(shared_runner) }

          it { expect(build).to be_nil }
        end

        context 'specific runner' do
          let(:build) { execute(specific_runner) }

          it { expect(build).to be_kind_of(Build) }
          it { expect(build).to be_valid }
          it { expect(build).to be_running }
          it { expect(build.runner).to eq(specific_runner) }
        end
      end

      context 'disallow when builds are disabled' do
        before do
          project.update(shared_runners_enabled: true)
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
        end

        context 'and uses shared runner' do
          let(:build) { execute(shared_runner) }

          it { expect(build).to be_nil }
        end

        context 'and uses specific runner' do
          let(:build) { execute(specific_runner) }

          it { expect(build).to be_nil }
        end
      end

      context 'when first build is stalled' do
        before do
          pending_job.update(lock_version: 0)
        end

        subject { described_class.new(specific_runner).execute }

        context 'with multiple builds are in queue' do
          let!(:other_build) { create :ci_build, pipeline: pipeline }

          before do
            allow_any_instance_of(Ci::RegisterJobService).to receive(:builds_for_specific_runner)
              .and_return(Ci::Build.where(id: [pending_job, other_build]))
          end

          it "receives second build from the queue" do
            expect(subject).to be_valid
            expect(subject.build).to eq(other_build)
          end
        end

        context 'when single build is in queue' do
          before do
            allow_any_instance_of(Ci::RegisterJobService).to receive(:builds_for_specific_runner)
              .and_return(Ci::Build.where(id: pending_job))
          end

          it "does not receive any valid result" do
            expect(subject).not_to be_valid
          end
        end

        context 'when there is no build in queue' do
          before do
            allow_any_instance_of(Ci::RegisterJobService).to receive(:builds_for_specific_runner)
              .and_return(Ci::Build.none)
          end

          it "does not receive builds but result is valid" do
            expect(subject).to be_valid
            expect(subject.build).to be_nil
          end
        end
      end

      context 'when access_level of runner is not_protected' do
        let!(:specific_runner) { create(:ci_runner, :specific) }

        context 'when a job is protected' do
          let!(:pending_job) { create(:ci_build, :protected, pipeline: pipeline) }

          it 'picks the job' do
            expect(execute(specific_runner)).to eq(pending_job)
          end
        end

        context 'when a job is unprotected' do
          let!(:pending_job) { create(:ci_build, pipeline: pipeline) }

          it 'picks the job' do
            expect(execute(specific_runner)).to eq(pending_job)
          end
        end

        context 'when protected attribute of a job is nil' do
          let!(:pending_job) { create(:ci_build, pipeline: pipeline) }

          before do
            pending_job.update_attribute(:protected, nil)
          end

          it 'picks the job' do
            expect(execute(specific_runner)).to eq(pending_job)
          end
        end
      end

      context 'when access_level of runner is ref_protected' do
        let!(:specific_runner) { create(:ci_runner, :ref_protected, :specific) }

        context 'when a job is protected' do
          let!(:pending_job) { create(:ci_build, :protected, pipeline: pipeline) }

          it 'picks the job' do
            expect(execute(specific_runner)).to eq(pending_job)
          end
        end

        context 'when a job is unprotected' do
          let!(:pending_job) { create(:ci_build, pipeline: pipeline) }

          it 'does not pick the job' do
            expect(execute(specific_runner)).to be_nil
          end
        end

        context 'when protected attribute of a job is nil' do
          let!(:pending_job) { create(:ci_build, pipeline: pipeline) }

          before do
            pending_job.update_attribute(:protected, nil)
          end

          it 'does not pick the job' do
            expect(execute(specific_runner)).to be_nil
          end
        end
      end

      context 'when "dependencies" keyword is specified' do
        shared_examples 'not pick' do
          it 'does not pick the build and drops the build' do
            expect(subject).to be_nil
            expect(pending_job.reload).to be_failed
            expect(pending_job).to be_missing_dependency_failure
          end
        end

        shared_examples 'validation is active' do
          context 'when depended job has not been completed yet' do
            let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

            it { expect(subject).to eq(pending_job) }
          end

          context 'when artifacts of depended job has been expired' do
            let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

            it_behaves_like 'not pick'
          end

          context 'when artifacts of depended job has been erased' do
            let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

            before do
              pre_stage_job.erase
            end

            it_behaves_like 'not pick'
          end

          context 'when job object is staled' do
            let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

            before do
              allow_any_instance_of(Ci::Build).to receive(:drop!)
                .and_raise(ActiveRecord::StaleObjectError.new(pending_job, :drop!))
            end

            it 'does not drop nor pick' do
              expect(subject).to be_nil
            end
          end
        end

        shared_examples 'validation is not active' do
          context 'when depended job has not been completed yet' do
            let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

            it { expect(subject).to eq(pending_job) }
          end
          context 'when artifacts of depended job has been expired' do
            let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

            it { expect(subject).to eq(pending_job) }
          end

          context 'when artifacts of depended job has been erased' do
            let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

            before do
              pre_stage_job.erase
            end

            it { expect(subject).to eq(pending_job) }
          end
        end

        before do
          stub_feature_flags(ci_disable_validates_dependencies: false)
        end

        let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0) }
        let!(:pending_job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 1, options: { dependencies: ['test'] } ) }

        subject { execute(specific_runner) }

        context 'when validates for dependencies is enabled' do
          before do
            stub_feature_flags(ci_disable_validates_dependencies: false)
          end

          it_behaves_like 'validation is active'
        end

        context 'when validates for dependencies is disabled' do
          before do
            stub_feature_flags(ci_disable_validates_dependencies: true)
          end

          it_behaves_like 'validation is not active'
        end
      end

      def execute(runner)
        described_class.new(runner).execute.build
      end
    end
  end
end
