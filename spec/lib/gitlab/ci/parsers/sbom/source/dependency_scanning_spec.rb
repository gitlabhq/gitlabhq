# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning do
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
      is_expected.to eq({
        'type' => :dependency_scanning,
        'data' => property_data,
        'fingerprint' => '4dbcb747e6f0fb3ed4f48d96b777f1d64acdf43e459fdfefad404e55c004a188'
      })
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
