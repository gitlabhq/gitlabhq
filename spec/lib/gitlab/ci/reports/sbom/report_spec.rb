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

  describe '#set_source' do
    let_it_be(:source) do
      {
        'type' => :dependency_scanning,
        'data' => {
          'input_file' => { 'path' => 'package-lock.json' },
          'source_file' => { 'path' => 'package.json' },
          'package_manager' => { 'name' => 'npm' },
          'language' => { 'name' => 'JavaScript' }
        },
        'fingerprint' => 'c01df1dc736c1148717e053edbde56cb3a55d3e31f87cea955945b6f67c17d42'
      }
    end

    it 'stores the source' do
      report.set_source(source)

      expect(report.source).to be_a(Gitlab::Ci::Reports::Sbom::Source)
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
