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
    let_it_be(:source) { create(:ci_reports_sbom_source) }

    it 'stores the source' do
      report.set_source(source)

      expect(report.source).to eq(source)
    end
  end

  describe '#add_component' do
    let_it_be(:components) { create_list(:ci_reports_sbom_component, 3) }

    it 'appends components to a list' do
      components.each { |component| report.add_component(component) }

      expect(report.components).to match_array(components)
    end
  end
end
