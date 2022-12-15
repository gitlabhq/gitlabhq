# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning, feature_category: :dependency_management do
  subject { described_class.source(property_data) }

  context 'when all property data is present' do
    let(:property_data) do
      {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    end

    it 'returns expected source data' do
      is_expected.to have_attributes(
        source_type: :dependency_scanning,
        data: property_data
      )
    end
  end

  context 'when required properties are missing' do
    let(:property_data) do
      {
        'category' => 'development',
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    end

    it { is_expected.to be_nil }
  end
end
