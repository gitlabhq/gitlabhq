# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Sequence do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build_stubbed(:ci_pipeline) }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project) }
  let(:first_step) { spy('first step', name: 'FirstStep') }
  let(:second_step) { spy('second step', name: 'SecondStep') }
  let(:sequence) { [first_step, second_step] }
  let(:histogram) { spy('prometheus metric') }

  subject do
    described_class.new(pipeline, command, sequence)
  end

  context 'when one of steps breaks the chain' do
    before do
      allow(first_step).to receive(:break?).and_return(true)
    end

    it 'does not process the second step' do
      subject.build!

      expect(second_step).not_to have_received(:perform!)
    end

    it 'returns a pipeline object' do
      expect(subject.build!).to eq pipeline
    end
  end

  context 'when all chains are executed correctly' do
    before do
      sequence.each do |step|
        allow(step).to receive(:break?).and_return(false)
      end
    end

    it 'iterates through entire sequence' do
      subject.build!

      expect(first_step).to have_received(:perform!)
      expect(second_step).to have_received(:perform!)
    end

    it 'returns a pipeline object' do
      expect(subject.build!).to eq pipeline
    end

    it 'adds sequence duration to duration histogram' do
      allow(command.metrics)
        .to receive(:pipeline_creation_duration_histogram)
        .and_return(histogram)

      subject.build!

      expect(histogram).to have_received(:observe)
    end

    it 'adds step sequence duration to duration histogram' do
      expect(command.metrics)
        .to receive(:pipeline_creation_step_duration_histogram)
        .twice
        .and_return(histogram)
      expect(histogram).to receive(:observe).with({ step: 'FirstStep' }, any_args).ordered
      expect(histogram).to receive(:observe).with({ step: 'SecondStep' }, any_args).ordered

      subject.build!
    end

    it 'records pipeline size by pipeline source in a histogram' do
      allow(command.metrics)
        .to receive(:pipeline_size_histogram)
        .and_return(histogram)

      subject.build!

      expect(histogram).to have_received(:observe)
        .with({ source: 'push', plan: project.actual_plan_name }, 0)
    end

    describe 'active jobs by pipeline plan histogram' do
      before do
        allow(command.metrics)
          .to receive(:active_jobs_histogram)
          .and_return(histogram)

        pipeline = create(:ci_pipeline, :running, project: project)
        create_list(:ci_build, 3, pipeline: pipeline)
        create(:ci_bridge, pipeline: pipeline)
      end

      it 'counts all the active jobs' do
        subject.build!

        expect(histogram).to have_received(:observe)
          .with(hash_including(plan: project.actual_plan_name), 4)
      end
    end
  end
end
