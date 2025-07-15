# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrackingHelper do
  describe '#tracking_attrs' do
    using RSpec::Parameterized::TableSyntax

    let(:input) { %w[a b c] }
    let(:result) { { data: { track_label: 'a', track_action: 'b', track_property: 'c' } } }

    it 'returns data hash' do
      expect(helper.tracking_attrs(*input)).to eq(result)
    end

    it 'can return data directly' do
      expect(helper.tracking_attrs_data(*input)).to eq(result[:data])
    end
  end
end
