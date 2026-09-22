# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::PartDefinition,
  feature_category: :value_stream_management do
  describe '#format_value' do
    using RSpec::Parameterized::TableSyntax

    subject(:formatted_value) { definition.format_value(value) }

    let(:definition) { described_class.new(:created_by_duo, :boolean) }

    where(:value, :expected) do
      0     | false
      1     | true
      false | false
      true  | true
      nil   | nil
    end

    with_them do
      it { is_expected.to eq(expected) }
    end

    context 'with a custom formatter' do
      let(:definition) { described_class.new(:created_by_duo, :boolean, formatter: ->(value) { value.zero? }) }
      let(:value) { 0 }

      it { is_expected.to be(true) }
    end

    context 'with an integer definition' do
      let(:definition) { described_class.new(:count, :integer) }
      let(:value) { 0 }

      it { is_expected.to eq(0) }
    end
  end
end
