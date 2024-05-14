# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Source::ContainerScanningForRegistry, feature_category: :container_scanning do
  subject { described_class.source(property_data) }

  context 'when required properties are present' do
    let(:property_data) do
      {
        'image' => {
          'name' => 'photon',
          'tag' => '5.0-20231007'
        },
        'operating_system' => {
          'name' => 'Photon OS',
          'version' => '5.0'
        }
      }
    end

    it 'returns expected source data' do
      is_expected.to have_attributes(
        source_type: :container_scanning_for_registry,
        data: property_data
      )
    end
  end

  context 'when required properties are missing' do
    let(:property_data) do
      {
        'operating_system' => {
          'name' => 'Photon OS',
          'version' => '5.0'
        }
      }
    end

    it { is_expected.to be_nil }
  end

  context 'when some operating_system properties are missing' do
    let(:property_data) do
      {
        'image' => {
          'name' => 'photon',
          'tag' => '5.0-20231007'
        },
        'operating_system' => {
          'name' => 'Photon OS'
        }
      }
    end

    it { is_expected.to be_nil }
  end
end
