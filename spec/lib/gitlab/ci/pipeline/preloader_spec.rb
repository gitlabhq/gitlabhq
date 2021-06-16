# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Preloader do
  let(:stage) { double(:stage) }
  let(:commit) { double(:commit) }
  let(:scheduled_action) { double(:scheduled_action) }
  let(:manual_action) { double(:manual_action) }

  let(:pipeline) do
    double(:pipeline, commit: commit, stages: [stage], scheduled_actions: [scheduled_action], manual_actions: [manual_action])
  end

  describe '.preload!' do
    context 'when preloading multiple commits' do
      let(:project) { create(:project, :repository) }

      it 'preloads all commits once' do
        expect(Commit).to receive(:decorate).once.and_call_original

        pipelines = [build_pipeline(ref: 'HEAD'),
                     build_pipeline(ref: 'HEAD~1')]

        described_class.preload!(pipelines)
      end

      def build_pipeline(ref:)
        build_stubbed(:ci_pipeline, project: project, sha: project.commit(ref).id)
      end
    end

    it 'preloads commit authors, number of warnings and ref commits' do
      expect(commit).to receive(:lazy_author)
      expect(pipeline).to receive(:lazy_ref_commit)
      expect(pipeline).to receive(:number_of_warnings)
      expect(stage).to receive(:number_of_warnings)
      expect(scheduled_action).to receive(:persisted_environment)
      expect(manual_action).to receive(:persisted_environment)

      described_class.preload!([pipeline])
    end

    it 'returns original collection' do
      allow(commit).to receive(:lazy_author)
      allow(pipeline).to receive(:lazy_ref_commit)
      allow(pipeline).to receive(:number_of_warnings)
      allow(stage).to receive(:number_of_warnings)
      allow(scheduled_action).to receive(:persisted_environment)
      allow(manual_action).to receive(:persisted_environment)

      pipelines = [pipeline, pipeline]

      expect(described_class.preload!(pipelines)).to eq pipelines
    end
  end
end
