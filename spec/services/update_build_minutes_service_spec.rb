require 'spec_helper'

describe UpdateBuildMinutesService, services: true do
  context '#perform' do
    let(:namespace) { create(:namespace) }
    let(:project) { create(:empty_project, namespace: namespace) }
    let(:pipeline) { create(:ci_pipeline) }
    let(:build) do
      create(:ci_build, :success,
        runner: runner, pipeline: pipeline,
        started_at: 2.hours.ago, finished_at: 1.hour.ago)
    end

    subject { described_class.new(project, nil).execute(build) }

    context 'with shared runner' do
      let(:runner) { create(:ci_runner, :shared) }

      it "creates a metrics and sets duration" do
        subject

        expect(project.project_statistics.reload.shared_runners_minutes).
          to eq(build.duration.to_i)

        expect(namespace.namespace_statistics.reload.shared_runners_minutes).
          to eq(build.duration.to_i)
      end

      context 'when metrics are created' do
        before do
          project.create_project_statistics(shared_runners_minutes: 100)
          namespace.create_namespace_metrics(shared_runners_minutes: 100)
        end

        it "updates metrics and adds duration" do
          subject

          expect(project.project_statistics.reload.shared_runners_minutes).
            to eq(100 + build.duration.to_i)

          expect(namespace.namespace_statistics.reload.shared_runners_minutes).
            to eq(100 + build.duration.to_i)
        end
      end
    end

    context 'for specific runner' do
      let(:runner) { create(:ci_runner) }

      it "does not create metrics" do
        subject

        expect(project.project_statistics).to be_nil
        expect(namespace.namespace_statistics).to be_nil
      end
    end
  end
end
