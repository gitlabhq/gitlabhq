# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Source::DependencyScanningComponent, feature_category: :software_composition_analysis do
  subject { described_class.source(property_data) }

  context 'when required properties are present' do
    let(:property_data) { { 'reachability' => 'unknown' } }

    it 'returns expected source data' do
      is_expected.to have_attributes(
        source_type: :dependency_scanning_component,
        data: property_data
      )
    end
  end

  context 'when required properties are missing' do
    let(:property_data) { {} }

    it { is_expected.to be_nil }
  end
end
