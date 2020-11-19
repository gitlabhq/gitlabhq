# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/crystalball/coverage_lines_strategy'

RSpec.describe Tooling::Crystalball::CoverageLinesStrategy do
  subject { described_class.new(execution_detector) }

  let(:execution_detector) { instance_double('Tooling::Crystalball::CoverageLinesExecutionDetector') }

  describe '#after_register' do
    it 'starts coverage' do
      expect(Coverage).to receive(:start).with(lines: true)
      subject.after_register
    end
  end
end
