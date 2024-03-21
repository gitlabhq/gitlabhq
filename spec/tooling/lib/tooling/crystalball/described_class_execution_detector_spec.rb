# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/crystalball/described_class_execution_detector'

RSpec.describe Tooling::Crystalball::DescribedClassExecutionDetector, feature_category: :tooling do
  subject(:detector) { described_class.new(root_path: root, exclude_prefixes: %w[vendor/ruby]) }

  let(:root) { '/tmp' }
  let(:path) { '/tmp/file.rb' }

  describe '#filter' do
    subject { detector.filter([path]) }

    it { is_expected.to eq(%w[file.rb]) }

    context 'with path in excluded prefix' do
      let(:path) { '/tmp/vendor/ruby/dependency.rb' }

      it { is_expected.to eq([]) }
    end
  end
end
