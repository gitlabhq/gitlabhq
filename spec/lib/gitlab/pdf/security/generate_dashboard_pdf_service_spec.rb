# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::GenerateDashboardPdfService, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:tempfile) { Tempfile.new(['report', '.pdf']) }
  let(:filename) { tempfile.path }
  let(:report_data) { ActiveSupport::HashWithIndifferentAccess.new({}) }
  let(:exportable) { project }
  let(:vulnerabilities_by_age_svg) do
    svg_content = <<~SVG.strip
      <svg width="590" height="466" xmlns="http://www.w3.org/2000/svg">
      <rect width="590" height="466" fill="none"/>
      </svg>
    SVG

    "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg_content)}"
  end

  let(:total_risk_score_svg) do
    svg_content = <<~SVG.strip
      <svg width="590" height="466" xmlns="http://www.w3.org/2000/svg">
      <rect width="590" height="466" fill="none"/>
      </svg>
    SVG

    "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg_content)}"
  end

  let(:stub_svg) do
    svg_content = <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg">
      <rect width="100" height="100"/>
      </svg>
    SVG

    "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg_content)}"
  end

  let(:stub_group_vulnerabilities_data) do
    { 'charts' => [], 'selected_day_range' => 30, 'date_info' => 'Jan 1 - Jan 31' }
  end

  let(:stub_project_security_status_data) { { 'grades' => [] } }
  let(:stub_vulnerabilities_by_severity_count_data) do
    {
      'critical' => { 'count' => 18, 'medianAge' => 96.06 },
      'high' => { 'count' => 74, 'medianAge' => 55.74 }
    }
  end

  subject(:service) { described_class.new(filename, report_data, exportable) }

  before do
    allow(Gitlab::PDF::Security::ProjectVulnerabilitiesHistory).to receive(:render)
    allow(Gitlab::PDF::Security::GroupVulnerabilitiesHistory).to receive(:render)
    allow(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).to receive(:render)
    allow(Gitlab::PDF::Security::VulnerabilitiesByAge).to receive(:render)
    allow(Gitlab::PDF::Security::TotalRiskScore).to receive(:render)
    allow(Gitlab::PDF::Security::VulnerabilitiesBySeverityCount).to receive(:render)
    allow(Gitlab::PDF::Security::VulnerabilitiesOverTime).to receive(:render)
  end

  after do
    tempfile.close
    tempfile.unlink
  end

  context 'when exportable is a project' do
    let(:exportable) { project }
    let(:report_data) do
      ActiveSupport::HashWithIndifferentAccess.new(
        'project_vulnerabilities_history' => { 'svg' => stub_svg },
        'group_vulnerabilities_over_time' => stub_group_vulnerabilities_data
      )
    end

    it 'does not render group-specific sections' do
      service.execute

      expect(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).not_to have_received(:render)
    end

    it 'renders vulnerabilities by severity count' do
      service.execute

      expect(Gitlab::PDF::Security::VulnerabilitiesBySeverityCount).to have_received(:render)
    end
  end

  context 'when exportable is a group' do
    let(:exportable) { group }
    let(:report_data) do
      ActiveSupport::HashWithIndifferentAccess.new(
        'project_vulnerabilities_history' => { 'svg' => stub_svg },
        'group_vulnerabilities_over_time' => stub_group_vulnerabilities_data,
        'project_security_status' => stub_project_security_status_data,
        'total_risk_score' => { 'svg' => total_risk_score_svg },
        'vulnerabilities_by_age' => { 'svg' => vulnerabilities_by_age_svg },
        'vulnerabilities_by_severity_count' => stub_vulnerabilities_by_severity_count_data
      )
    end

    it 'renders total risk score with correct data' do
      service.execute

      expect(Gitlab::PDF::Security::TotalRiskScore).to have_received(:render).with(
        anything,
        data: { svg: total_risk_score_svg }
      )
    end

    it 'renders vulnerabilities by age with correct data' do
      service.execute

      expect(Gitlab::PDF::Security::VulnerabilitiesByAge).to have_received(:render).with(
        anything,
        data: { svg: vulnerabilities_by_age_svg }
      )
    end

    it 'renders vulnerabilities by severity count with correct data' do
      service.execute

      expect(Gitlab::PDF::Security::VulnerabilitiesBySeverityCount).to have_received(:render).with(
        anything,
        data: stub_vulnerabilities_by_severity_count_data
      )
    end

    it 'renders all components with their expected data' do
      service.execute

      expect(Gitlab::PDF::Security::ProjectVulnerabilitiesHistory).to have_received(:render).with(
        anything, data: { svg: stub_svg }
      )
      expect(Gitlab::PDF::Security::GroupVulnerabilitiesHistory).to have_received(:render).with(
        anything, data: stub_group_vulnerabilities_data
      )
      expect(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).to have_received(:render).with(
        anything, data: stub_project_security_status_data
      )
    end
  end

  describe 'conditional section rendering' do
    let(:exportable) { group }

    context 'when total risk score data is present' do
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new('total_risk_score' => { 'svg' => total_risk_score_svg })
      end

      it 'renders total risk score' do
        service.execute

        expect(Gitlab::PDF::Security::TotalRiskScore).to have_received(:render)
      end
    end

    context 'when total risk score data is missing' do
      it 'does not render total risk score' do
        service.execute

        expect(Gitlab::PDF::Security::TotalRiskScore).not_to have_received(:render)
      end
    end

    context 'when vulnerabilities by age data is present' do
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new(
          'vulnerabilities_by_age' => { 'svg' => vulnerabilities_by_age_svg }
        )
      end

      it 'renders vulnerabilities by age for a group' do
        service.execute

        expect(Gitlab::PDF::Security::VulnerabilitiesByAge).to have_received(:render)
      end

      context 'when exportable is a project' do
        let(:exportable) { project }

        it 'renders vulnerabilities by age with correct data for a project' do
          service.execute

          expect(Gitlab::PDF::Security::VulnerabilitiesByAge).to have_received(:render).with(
            anything,
            data: { svg: vulnerabilities_by_age_svg }
          )
        end
      end
    end

    context 'when vulnerabilities by age data is missing' do
      it 'does not render vulnerabilities by age' do
        service.execute

        expect(Gitlab::PDF::Security::VulnerabilitiesByAge).not_to have_received(:render)
      end
    end

    context 'when only group security status is present' do
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new(
          'project_security_status' => stub_project_security_status_data
        )
      end

      it 'renders group security status and skips total risk score' do
        service.execute

        expect(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).to have_received(:render)
        expect(Gitlab::PDF::Security::TotalRiskScore).not_to have_received(:render)
      end
    end

    context 'when group security status and total risk score are both present' do
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new(
          'project_security_status' => stub_project_security_status_data,
          'total_risk_score' => { 'svg' => total_risk_score_svg }
        )
      end

      it 'renders both sections' do
        service.execute

        expect(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).to have_received(:render)
        expect(Gitlab::PDF::Security::TotalRiskScore).to have_received(:render)
      end
    end

    context 'when total risk score data is present for a project' do
      let(:exportable) { project }
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new('total_risk_score' => { 'svg' => total_risk_score_svg })
      end

      it 'renders total risk score' do
        service.execute

        expect(Gitlab::PDF::Security::TotalRiskScore).to have_received(:render)
      end
    end

    context 'when only vulnerabilities over time data is present for a project' do
      let(:exportable) { project }
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new('open_vulnerabilities_over_time' => { 'svg' => stub_svg })
      end

      it 'renders vulnerabilities over time' do
        service.execute

        expect(Gitlab::PDF::Security::VulnerabilitiesOverTime).to have_received(:render)
      end
    end

    context 'when multiple dashboard graphs are present' do
      let(:report_data) do
        ActiveSupport::HashWithIndifferentAccess.new(
          'project_security_status' => stub_project_security_status_data,
          'total_risk_score' => { 'svg' => total_risk_score_svg },
          'open_vulnerabilities_over_time' => { 'svg' => stub_svg }
        )
      end

      it 'renders all present sections' do
        service.execute

        expect(Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades).to have_received(:render)
        expect(Gitlab::PDF::Security::TotalRiskScore).to have_received(:render)
        expect(Gitlab::PDF::Security::VulnerabilitiesOverTime).to have_received(:render)
      end
    end
  end

  describe 'ensure_space_for' do
    let(:exportable) { group }
    let(:report_data) do
      ActiveSupport::HashWithIndifferentAccess.new(
        'total_risk_score' => { 'svg' => total_risk_score_svg },
        'vulnerabilities_by_age' => { 'svg' => vulnerabilities_by_age_svg }
      )
    end

    context 'when vulnerabilities by age does not fit on the current page' do
      it 'starts a new page so the chart renders on a fresh page' do
        total_risk_score_page = nil
        vulnerabilities_by_age_page = nil

        # consume enough space before the risk row so that after the fixed-height bounding_box
        # the remaining page height is insufficient for vulnerabilities by age
        allow(Gitlab::PDF::Security::VulnerabilitiesBySeverityCount).to receive(:render) do |pdf, **|
          pdf.move_down 250
        end

        allow(Gitlab::PDF::Security::TotalRiskScore).to receive(:render) do |pdf, **|
          total_risk_score_page = pdf.page_number
        end

        allow(Gitlab::PDF::Security::VulnerabilitiesByAge).to receive(:render) do |pdf, **|
          vulnerabilities_by_age_page = pdf.page_number
        end

        service.execute

        expect(vulnerabilities_by_age_page).to be > total_risk_score_page
      end
    end
  end
end
