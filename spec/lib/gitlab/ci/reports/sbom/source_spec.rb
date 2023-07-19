# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Source, feature_category: :dependency_management do
  let(:attributes) do
    {
      type: :dependency_scanning,
      data: {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    }
  end

  subject { described_class.new(**attributes) }

  it 'has correct attributes' do
    expect(subject).to have_attributes(
      source_type: attributes[:type],
      data: attributes[:data]
    )
  end

  describe '#source_file_path' do
    it 'returns the correct source_file_path' do
      expect(subject.source_file_path).to eq('package.json')
    end
  end

  describe '#input_file_path' do
    it 'returns the correct input_file_path' do
      expect(subject.input_file_path).to eq("package-lock.json")
    end
  end

  describe '#packager' do
    it 'returns the correct package manager name' do
      expect(subject.packager).to eq("npm")
    end
  end

  describe '#language' do
    it 'returns the correct langauge' do
      expect(subject.language).to eq("JavaScript")
    end
  end
end
