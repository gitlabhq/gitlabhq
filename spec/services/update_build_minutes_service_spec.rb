require 'spec_helper'

describe UpdateBuildMinutesService do
  context '#perform' do
    let(:namespace) { create(:namespace, shared_runners_minutes_limit: 100) }
    let(:project) { create(:empty_project, namespace: namespace) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) do
      create(:ci_build, :success,
        runner: runner, pipeline: pipeline,
        started_at: 2.hours.ago, finished_at: 1.hour.ago)
    end

    subject { described_class.new(project, nil).execute(build) }

    context 'with shared runner' do
      let(:runner) { create(:ci_runner, :shared) }

      it "creates a statistics and sets duration" do
        subject

        expect(project.statistics.reload.shared_runners_seconds)
          .to eq(build.duration.to_i)

        expect(namespace.namespace_statistics.reload.shared_runners_seconds)
          .to eq(build.duration.to_i)
      end

      context 'when statistics are created' do
        before do
          project.statistics.update(shared_runners_seconds: 100)
          namespace.create_namespace_statistics(shared_runners_seconds: 100)
        end

        it "updates statistics and adds duration" do
          subject

          expect(project.statistics.reload.shared_runners_seconds)
            .to eq(100 + build.duration.to_i)

          expect(namespace.namespace_statistics.reload.shared_runners_seconds)
            .to eq(100 + build.duration.to_i)
        end
      end
    end

    context 'for specific runner' do
      let(:runner) { create(:ci_runner) }

      it "does not create statistics" do
        subject

        expect(namespace.namespace_statistics).to be_nil
      end
    end
  end
end
