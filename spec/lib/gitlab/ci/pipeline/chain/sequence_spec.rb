# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Sequence do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build_stubbed(:ci_pipeline) }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new }
  let(:first_step) { spy('first step') }
  let(:second_step) { spy('second step') }
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
      subject.build! do |pipeline, sequence|
        expect(sequence).not_to be_complete
      end

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
      subject.build! do |pipeline, sequence|
        expect(sequence).to be_complete
      end

      expect(first_step).to have_received(:perform!)
      expect(second_step).to have_received(:perform!)
    end

    it 'returns a pipeline object' do
      expect(subject.build!).to eq pipeline
    end

    it 'adds sequence duration to duration histogram' do
      allow(command).to receive(:duration_histogram).and_return(histogram)

      subject.build!

      expect(histogram).to have_received(:observe)
    end
  end
end
