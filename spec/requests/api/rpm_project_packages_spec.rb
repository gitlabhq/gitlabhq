# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::RpmProjectPackages do
  include PackagesManagerApiSpecHelpers
  let(:project) { create(:project) }
  let(:headers) { {} }
  let(:package_name) { 'rpm-package.0-1.x86_64.rpm' }
  let(:package_file_id) { 1 }

  shared_examples 'an unimplemented route' do
    it_behaves_like 'returning response status', :not_found

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(rpm_packages: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'when package feature is disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      it_behaves_like 'returning response status', :not_found
    end
  end

  describe 'GET /api/v4/projects/:project_id/packages/rpm/repodata/:filename' do
    let(:url) { api("/projects/#{project.id}/packages/rpm/repodata/#{package_name}") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rpm/:package_file_id/:filename' do
    let(:url) { api("/projects/#{project.id}/packages/rpm/#{package_file_id}/#{package_name}") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rpm/authorize' do
    let(:url) { api("/projects/#{project.id}/packages/rpm/authorize") }

    subject { post(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rpm' do
    let(:url) { api("/projects/#{project.id}/packages/rpm") }

    subject { post(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end
end
