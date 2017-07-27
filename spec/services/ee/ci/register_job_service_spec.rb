require 'spec_helper'

module Ci
  describe RegisterJobService do
    let!(:project) { create :empty_project, shared_runners_enabled: false }
    let!(:pipeline) { create :ci_empty_pipeline, project: project }
    let!(:pending_build) { create :ci_build, pipeline: pipeline }
    let(:shared_runner) { create(:ci_runner, :shared) }

    describe '#execute' do
      context 'for project with shared runners when global minutes limit is set' do
        before do
          project.update(shared_runners_enabled: true)
          stub_application_setting(shared_runners_minutes: 100)
        end

        context 'allow to pick builds' do
          let(:build) { execute(shared_runner) }

          it { expect(build).to be_kind_of(Build) }
        end

        context 'when over the global quota' do
          before do
            project.namespace.create_namespace_statistics(
              shared_runners_seconds: 6001)
          end

          let(:build) { execute(shared_runner) }

          it "does not return a build" do
            expect(build).to be_nil
          end

          context 'when project is public' do
            before do
              project.update(visibility_level: Project::PUBLIC)
            end

            it "does return the build" do
              expect(build).to be_kind_of(Build)
            end
          end

          context 'when namespace limit is set to unlimited' do
            before do
              project.namespace.update(shared_runners_minutes_limit: 0)
            end

            it "does return the build" do
              expect(build).to be_kind_of(Build)
            end
          end

          context 'when namespace quota is bigger than a global one' do
            before do
              project.namespace.update(shared_runners_minutes_limit: 101)
            end

            it "does return the build" do
              expect(build).to be_kind_of(Build)
            end
          end
        end
      end

      def execute(runner)
        described_class.new(runner).execute.build
      end
    end
  end
end
