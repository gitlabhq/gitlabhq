# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }
  let(:data) do
    {
      vulnerability_grades: [
        {
          grade: "F",
          count: 296,
          projects: {
            nodes: [
              {
                name: "Oxeye Rulez",
                nameWithNamespace: "Gitlab Org / Oxeye Rulez",
                securityDashboardPath: "/gitlab-org/oxeye-rulez/-/security/dashboard",
                vulnerabilitySeveritiesCount: severities_data(critical: 295, high: 1070)
              },
              {
                name: "Security Reports",
                nameWithNamespace: "Gitlab Org / Security Reports",
                securityDashboardPath: "/gitlab-org/security-reports/-/security/dashboard",
                vulnerabilitySeveritiesCount: severities_data(critical: 1)
              }
            ]
          }
        },
        {
          grade: "D",
          count: 10,
          projects: {
            nodes: [
              {
                name: "Cwe 78 Cwe 89 Tests",
                nameWithNamespace: "Gitlab Org / Cwe 78 Cwe 89 Tests",
                securityDashboardPath: "/gitlab-org/cwe-78-cwe-89-tests/-/security/dashboard",
                vulnerabilitySeveritiesCount: severities_data(high: 10)
              },
              { name: "Project 2", nameWithNamespace: "Gitlab Org / Project 2",
                vulnerabilitySeveritiesCount: severities_data },
              { name: "Project 3", nameWithNamespace: "Gitlab Org / Project 3",
                vulnerabilitySeveritiesCount: severities_data },
              { name: "Project 4", nameWithNamespace: "Gitlab Org / Project 4",
                vulnerabilitySeveritiesCount: severities_data },
              { name: "Project 5", nameWithNamespace: "Gitlab Org / Project 5",
                vulnerabilitySeveritiesCount: severities_data },
              { name: "Project 6", nameWithNamespace: "Gitlab Org / Project 6",
                vulnerabilitySeveritiesCount: severities_data }
            ]
          }
        }
      ],
      expanded_grade: "F"
    }.with_indifferent_access
  end

  def severities_data(severities = {})
    { critical: 0, high: 0, info: 0, low: 0, medium: 0, unknown: 0 }
      .merge(severities)
  end

  describe '.render' do
    subject(:render) { described_class.render(pdf, data: data) }

    let(:mock_instance) { instance_double(described_class) }

    before do
      allow(mock_instance).to receive(:render)
      allow(described_class).to receive(:new).and_return(mock_instance)
    end

    it 'creates a new instance and calls render on it' do
      render

      expect(described_class).to have_received(:new).with(pdf, data).once
      expect(mock_instance).to have_received(:render).exactly(:once)
    end
  end

  describe '#render' do
    subject(:render_grades) { described_class.render(pdf, data: data) }

    before do
      allow(pdf).to receive(:text_box).and_call_original
      allow(pdf).to receive(:svg).and_call_original
    end

    let(:expected_labels) do
      [
        s_('Project security status'),
        s_('Projects are graded based on the highest severity vulnerability present')
      ]
    end

    it 'includes expected text elements' do
      render_grades

      expected_labels.each do |label|
        expect(pdf).to have_received(:text_box).with(label, any_args).once
      end
    end

    it 'renders the SVG table layout' do
      render_grades

      expect(pdf).to have_received(:svg).with(%r{<svg.*</svg>}m, any_args).at_least(:once)
    end

    context 'when data is nil' do
      let(:data) { nil }

      it 'returns :noop without rendering anything' do
        expect(render_grades).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end

    context 'when data is blank' do
      let(:data) { {} }

      it 'returns :noop without rendering anything' do
        expect(render_grades).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end
  end
end
