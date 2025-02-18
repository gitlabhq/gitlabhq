# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupPackages, feature_category: :package_registry do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group, name: 'project A', path: 'project-a') }
  let_it_be(:user) { create(:user) }

  let(:params) { {} }

  subject { get api(url), params: params }

  describe 'GET /groups/:id/packages' do
    let(:url) { "/groups/#{group.id}/packages" }
    let(:package_schema) { 'public_api/v4/packages/group_packages' }

    context 'with sorting' do
      let_it_be(:package1) { create(:npm_package, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1") }
      let_it_be(:package2) { create(:nuget_package, project: project, version: '2.0.4') }

      let(:package3) { create(:maven_package, project: project, version: '1.1.1', name: 'zzz') }

      before do
        travel_to(1.day.ago) do
          package3
        end
      end

      context 'without sorting params' do
        let(:packages) { [package3, package1, package2] }

        it 'sorts by created_at asc' do
          subject

          expect(json_response.map { |package| package['id'] }).to eq(packages.map(&:id))
        end
      end

      it_behaves_like 'package sorting', 'name' do
        let(:packages) { [package1, package2, package3] }
      end

      it_behaves_like 'package sorting', 'created_at' do
        let(:packages) { [package3, package1, package2] }
      end

      it_behaves_like 'package sorting', 'version' do
        let(:packages) { [package3, package2, package1] }
      end

      it_behaves_like 'package sorting', 'type' do
        let(:packages) { [package3, package1, package2] }
      end

      it_behaves_like 'package sorting', 'project_path' do
        let_it_be(:another_project) { create(:project, :public, namespace: group, name: 'project B', path: 'project-b') }
        let_it_be(:package4) { create(:npm_package, project: another_project, version: '3.1.0', name: "@#{project.root_namespace.path}/bar") }

        let(:packages) { [package3, package2, package1, package4] }
        let(:package_ids_desc) { [package4.id, package3.id, package2.id, package1.id] }
      end
    end

    context 'with private group' do
      let!(:package1) { create(:generic_package, project: project) }
      let!(:package2) { create(:generic_package, project: project) }

      let(:group) { create(:group, :private) }
      let(:subgroup) { create(:group, :private, parent: group) }
      let(:project) { create(:project, :private, namespace: group) }
      let(:subproject) { create(:project, :private, namespace: subgroup) }

      context 'with unauthenticated user' do
        it_behaves_like 'rejects packages access', :group, :no_type, :not_found
      end

      context 'with authenticated user' do
        subject { get api(url, user) }

        it_behaves_like 'returns packages', :group, :owner
        it_behaves_like 'returns packages', :group, :maintainer
        it_behaves_like 'returns packages', :group, :developer
        it_behaves_like 'returns packages', :group, :reporter
        it_behaves_like 'returns packages', :group, :guest

        context 'with subgroup' do
          let(:subgroup) { create(:group, :private, parent: group) }
          let(:subproject) { create(:project, :private, namespace: subgroup) }
          let!(:package3) { create(:npm_package, project: subproject) }

          it_behaves_like 'returns packages with subgroups', :group, :owner
          it_behaves_like 'returns packages with subgroups', :group, :maintainer
          it_behaves_like 'returns packages with subgroups', :group, :developer
          it_behaves_like 'returns packages with subgroups', :group, :reporter
          it_behaves_like 'returns packages with subgroups', :group, :guest

          context 'excluding subgroup' do
            let(:url) { "/groups/#{group.id}/packages?exclude_subgroups=true" }

            it_behaves_like 'returns packages', :group, :owner
            it_behaves_like 'returns packages', :group, :maintainer
            it_behaves_like 'returns packages', :group, :developer
            it_behaves_like 'returns packages', :group, :reporter
            it_behaves_like 'returns packages', :group, :guest
          end
        end
      end
    end

    context 'with public group' do
      let_it_be(:package1) { create(:generic_package, project: project) }
      let_it_be(:package2) { create(:generic_package, project: project) }

      context 'with unauthenticated user' do
        it_behaves_like 'returns packages', :group, :no_type
      end

      context 'with authenticated user' do
        subject { get api(url, user) }

        it_behaves_like 'returns packages', :group, :owner
        it_behaves_like 'returns packages', :group, :maintainer
        it_behaves_like 'returns packages', :group, :developer
        it_behaves_like 'returns packages', :group, :reporter
        it_behaves_like 'returns packages', :group, :guest
      end
    end

    context 'with pagination params' do
      let_it_be(:package1) { create(:generic_package, project: project) }
      let_it_be(:package2) { create(:generic_package, project: project) }
      let_it_be(:package3) { create(:npm_package, project: project) }
      let_it_be(:package4) { create(:npm_package, project: project) }

      it_behaves_like 'returns paginated packages'
    end

    it_behaves_like 'filters on each package_type', is_project: false

    context 'filtering on package_version' do
      include_context 'package filter context'

      let!(:package1) { create(:nuget_package, project: project, version: '2.0.4') }
      let!(:package2) { create(:nuget_package, project: project) }

      it 'returns the versioned package' do
        url = group_filter_url(:version, '2.0.4')
        get api(url, user)

        expect(json_response.length).to eq(1)
        expect(json_response.first['version']).to eq(package1.version)
      end

      it 'include_versionless has no effect' do
        url = "/groups/#{group.id}/packages?package_version=2.0.4&include_versionless=true"
        get api(url, user)

        expect(json_response.length).to eq(1)
        expect(json_response.first['version']).to eq(package1.version)
      end
    end

    context 'does not accept non supported package_type value' do
      include_context 'package filter context'

      let(:url) { group_filter_url(:type, 'foo') }

      it_behaves_like 'returning response status', :bad_request
    end

    context 'with build info' do
      let_it_be(:package1) { create(:npm_package, :with_build, project: project) }

      it 'returns an empty array for the pipelines attribute' do
        subject

        expect(json_response.first['pipelines']).to be_empty
      end
    end

    context 'without build info' do
      it 'does not include the pipeline attributes' do
        subject

        expect(json_response).not_to include('pipeline', 'pipelines')
      end
    end

    it_behaves_like 'with versionless packages'
    it_behaves_like 'with status param'
    it_behaves_like 'does not cause n^2 queries'
  end
end
