require 'spec_helper'

describe Ci::Build, models: true do
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { build.shared_runners_minutes_limit_enabled? }

    context 'for shared runner' do
      before do
        build.runner = create(:ci_runner, :shared)
      end

      it do
        expect(build.project).to receive(:shared_runners_minutes_limit_enabled?)
          .and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'with specific runner' do
      before do
        build.runner = create(:ci_runner, :specific)
      end

      it { is_expected.to be_falsey }
    end

    context 'without runner' do
      it { is_expected.to be_falsey }
    end
  end

  context 'updates build minutes' do
    let(:build) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}" do
        expect(UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        build.public_send(event)
      end
    end
  end
end
