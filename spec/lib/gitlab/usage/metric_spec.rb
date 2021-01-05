# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metric do
  describe '#definition' do
    it 'returns generation_1 metric definiton' do
      expect(described_class.new(default_generation_path: 'uuid').definition).to be_an(Gitlab::Usage::MetricDefinition)
    end
  end

  describe '#unflatten_default_path' do
    using RSpec::Parameterized::TableSyntax

    where(:default_generation_path, :value, :expected_hash) do
      'uuid'                                     | nil    | { uuid: nil }
      'uuid'                                     | '1111' | { uuid: '1111' }
      'counts.issues'                            | nil    | { counts: { issues: nil } }
      'counts.issues'                            | 100    | { counts: { issues: 100 } }
      'usage_activity_by_stage.verify.ci_builds' | 100    | { usage_activity_by_stage: { verify: { ci_builds: 100 } } }
    end

    with_them do
      subject { described_class.new(default_generation_path: default_generation_path, value: value).unflatten_default_path }

      it { is_expected.to eq(expected_hash) }
    end
  end
end
