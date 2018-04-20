require 'spec_helper'

describe ListGcpProjectsService do
  include GoogleApi::CloudPlatformHelpers

  let(:service) { described_class.new }
  let(:project_id) { 'test-project-1234' }

  describe '#execute' do
    before do
      stub_cloud_platform_projects_list(project_id: project_id)
    end

    subject { service.execute('bogustoken') }

    context 'google account has a billing enabled gcp project' do
      before do
        stub_cloud_platform_projects_get_billing_info(project_id, true)
      end

      it { is_expected.to all(satisfy { |project| project.project_id == project_id }) }
    end

    context 'google account does not have a billing enabled gcp project' do
      before do
        stub_cloud_platform_projects_get_billing_info(project_id, false)
      end

      it { is_expected.to eq([]) }
    end
  end
end
