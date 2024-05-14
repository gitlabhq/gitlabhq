# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/crystalball/coverage_lines_strategy'

RSpec.describe Tooling::Crystalball::CoverageLinesStrategy, feature_category: :tooling do
  subject { described_class.new(execution_detector) }

  let(:execution_detector) { instance_double('Tooling::Crystalball::CoverageLinesExecutionDetector') }

  describe '#after_register' do
    context 'when Simplecov is not running' do
      before do
        allow(SimpleCov).to receive(:running).and_return(false)
      end

      it 'starts coverage' do
        expect(Coverage).to receive(:start).with(lines: true)

        subject.after_register
      end
    end

    context 'when Simplecov is running' do
      before do
        allow(SimpleCov).to receive(:running).and_return(true)
      end

      it 'dos not start coverage' do
        expect(Coverage).not_to receive(:start)

        subject.after_register
      end
    end
  end
end
