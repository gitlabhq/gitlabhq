require 'spec_helper'

module Ci
  describe RegisterBuildService, services: true do
    let!(:service) { RegisterBuildService.new }
    let!(:project) { FactoryGirl.create :empty_project, shared_runners_enabled: false }
    let!(:pipeline) { FactoryGirl.create :ci_pipeline, project: project }
    let!(:pending_build) { FactoryGirl.create :ci_build, pipeline: pipeline }
    let!(:shared_runner) { FactoryGirl.create(:ci_runner, is_shared: true) }
    let!(:specific_runner) { FactoryGirl.create(:ci_runner, is_shared: false) }

    before do
      specific_runner.assign_to(project)
    end

    describe '#execute' do
      context 'runner follow tag list' do
        it "picks build with the same tag" do
          pending_build.tag_list = ["linux"]
          pending_build.save
          specific_runner.tag_list = ["linux"]
          expect(service.execute(specific_runner)).to eq(pending_build)
        end

        it "does not pick build with different tag" do
          pending_build.tag_list = ["linux"]
          pending_build.save
          specific_runner.tag_list = ["win32"]
          expect(service.execute(specific_runner)).to be_falsey
        end

        it "picks build without tag" do
          expect(service.execute(specific_runner)).to eq(pending_build)
        end

        it "does not pick build with tag" do
          pending_build.tag_list = ["linux"]
          pending_build.save
          expect(service.execute(specific_runner)).to be_falsey
        end

        it "pick build without tag" do
          specific_runner.tag_list = ["win32"]
          expect(service.execute(specific_runner)).to eq(pending_build)
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
            expect(service.execute(shared_runner)).to be_nil
          end
        end

        context 'for specific runner' do
          it 'does not pick a build' do
            expect(service.execute(specific_runner)).to be_nil
          end
        end
      end

      context 'allow shared runners' do
        before do
          project.update(shared_runners_enabled: true)
        end

        context 'for multiple builds' do
          let!(:project2) { create :empty_project, shared_runners_enabled: true }
          let!(:pipeline2) { create :ci_pipeline, project: project2 }
          let!(:project3) { create :empty_project, shared_runners_enabled: true }
          let!(:pipeline3) { create :ci_pipeline, project: project3 }
          let!(:build1_project1) { pending_build }
          let!(:build2_project1) { FactoryGirl.create :ci_build, pipeline: pipeline }
          let!(:build3_project1) { FactoryGirl.create :ci_build, pipeline: pipeline }
          let!(:build1_project2) { FactoryGirl.create :ci_build, pipeline: pipeline2 }
          let!(:build2_project2) { FactoryGirl.create :ci_build, pipeline: pipeline2 }
          let!(:build1_project3) { FactoryGirl.create :ci_build, pipeline: pipeline3 }

          it 'prefers projects without builds first' do
            # it gets for one build from each of the projects
            expect(service.execute(shared_runner)).to eq(build1_project1)
            expect(service.execute(shared_runner)).to eq(build1_project2)
            expect(service.execute(shared_runner)).to eq(build1_project3)

            # then it gets a second build from each of the projects
            expect(service.execute(shared_runner)).to eq(build2_project1)
            expect(service.execute(shared_runner)).to eq(build2_project2)

            # in the end the third build
            expect(service.execute(shared_runner)).to eq(build3_project1)
          end

          it 'equalises number of running builds' do
            # after finishing the first build for project 1, get a second build from the same project
            expect(service.execute(shared_runner)).to eq(build1_project1)
            build1_project1.success
            expect(service.execute(shared_runner)).to eq(build2_project1)

            expect(service.execute(shared_runner)).to eq(build1_project2)
            build1_project2.success
            expect(service.execute(shared_runner)).to eq(build2_project2)
            expect(service.execute(shared_runner)).to eq(build1_project3)
            expect(service.execute(shared_runner)).to eq(build3_project1)
          end
        end

        context 'shared runner' do
          let(:build) { service.execute(shared_runner) }

          it { expect(build).to be_kind_of(Build) }
          it { expect(build).to be_valid }
          it { expect(build).to be_running }
          it { expect(build.runner).to eq(shared_runner) }
        end

        context 'specific runner' do
          let(:build) { service.execute(specific_runner) }

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
          let(:build) { service.execute(shared_runner) }

          it { expect(build).to be_nil }
        end

        context 'specific runner' do
          let(:build) { service.execute(specific_runner) }

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
          let(:build) { service.execute(shared_runner) }

          it { expect(build).to be_nil }
        end

        context 'and uses specific runner' do
          let(:build) { service.execute(specific_runner) }

          it { expect(build).to be_nil }
        end
      end
    end
  end
end
