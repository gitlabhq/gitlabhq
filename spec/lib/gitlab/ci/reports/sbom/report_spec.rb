# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Report, feature_category: :dependency_management do
  subject(:report) { described_class.new }

  describe '#valid?' do
    context 'when there are no errors' do
      it { is_expected.to be_valid }
    end

    context 'when report contains errors' do
      before do
        report.add_error('error1')
        report.add_error('error2')
      end

      it { is_expected.not_to be_valid }
    end
  end

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

  describe 'ensure_ancestors!' do
    let_it_be(:components) { create_list(:ci_reports_sbom_component, 3) }
    let_it_be(:component_first) { components.first }
    let_it_be(:component_last) { components.last }
    let_it_be(:expected_value) { { name: component_first.name, version: component_first.version } }

    it 'stores hierachies' do
      components.each { |component| report.add_component(component) }
      report.add_dependency(component_first.ref, component_last.ref)

      report.ensure_ancestors!

      expect(component_last.ancestors).to match_array([expected_value])
    end
  end
end
