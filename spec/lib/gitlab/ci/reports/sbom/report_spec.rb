# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Report do
  subject(:report) { described_class.new }

  describe '#add_error' do
    it 'appends errors to a list' do
      report.add_error('error1')
      report.add_error('error2')

      expect(report.errors).to match_array(%w[error1 error2])
    end
  end

  describe '#add_source' do
    let_it_be(:sources) do
      [
        {
          'type' => :dependency_file,
          'data' => {
            'input_file' => { 'name' => 'package-lock.json' },
            'package_manager' => { 'name' => 'npm' },
            'language' => { 'name' => 'JavaScript' }
          },
          'fingerprint' => '4ee1623c8f3ddd152b3c1fc340b3ece3cbcf807efa2726307ea34e7d6d36a6c1'
        },
        {
          'type' => :dependency_file,
          'data' => {
            'input_file' => { 'name' => 'go.sum' },
            'package_manager' => { 'name' => 'go' },
            'language' => { 'name' => 'Go' }
          },
          'fingerprint' => 'e78eee13d87248d5b7e3df21de67365a4996b3a547e033b8e8b180b24c300fd8'
        }
      ]
    end

    it 'stores each source with the given attributes' do
      sources.each { |source| report.add_source(source) }

      expect(report.sources.size).to eq(2)
      expect(report.sources).to all(be_a(Gitlab::Ci::Reports::Sbom::Source))
    end
  end

  describe '#add_component' do
    let_it_be(:components) do
      [
        { 'type' => 'library', 'name' => 'component1', 'version' => 'v0.0.1' },
        { 'type' => 'library', 'name' => 'component2', 'version' => 'v0.0.2' },
        { 'type' => 'library', 'name' => 'component2' }
      ]
    end

    it 'appends components to a list' do
      components.each { |component| report.add_component(component) }

      expect(report.components.size).to eq(3)
      expect(report.components).to all(be_a(Gitlab::Ci::Reports::Sbom::Component))
    end
  end
end
