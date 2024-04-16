# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/crystalball/coverage_lines_execution_detector'

RSpec.describe Tooling::Crystalball::CoverageLinesExecutionDetector, feature_category: :tooling do
  subject(:detector) { described_class.new(root, exclude_prefixes: %w[vendor/ruby]) }

  let(:root) { '/tmp' }
  let(:before_map) { { path => { lines: [0, 2, nil] } } }
  let(:after_map) { { path => { lines: [0, 3, nil] } } }
  let(:path) { '/tmp/file.rb' }

  describe '#detect' do
    subject { detector.detect(before_map, after_map) }

    it { is_expected.to eq(%w[file.rb]) }

    context 'with no changes' do
      let(:after_map) { { path => { lines: [0, 2, nil] } } }

      it { is_expected.to eq([]) }
    end

    context 'with previously uncovered file' do
      let(:before_map) { {} }

      it { is_expected.to eq(%w[file.rb]) }
    end

    context 'with path outside of root' do
      let(:path) { '/abc/file.rb' }

      it { is_expected.to eq([]) }
    end

    context 'with path in excluded prefix' do
      let(:path) { '/tmp/vendor/ruby/dependency.rb' }

      it { is_expected.to eq([]) }
    end
  end
end
