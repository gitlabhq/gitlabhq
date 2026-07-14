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

    it_behaves_like 'authorizing granular token permissions', :read_package do
      before_all { group.add_developer(user) }

      let(:boundary_object) { group }
      let(:request) { get api(url, personal_access_token: pat) }
    end

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

        context 'with a private project alongside the public project' do
          let_it_be(:private_project) { create(:project, :private, namespace: group) }
          let_it_be(:private_package) { create(:generic_package, project: private_project) }

          it 'returns only packages from public projects' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package1.id, package2.id)
          end
        end
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

    context 'when a project has the package registry disabled', :aggregate_failures do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:enabled_project) { create(:project, :private, group: group) }
      let_it_be(:disabled_project) do
        create(:project, :private, group: group,
          package_registry_access_level: ProjectFeature::DISABLED, packages_enabled: false)
      end

      let_it_be(:visible_package) { create(:generic_package, project: enabled_project) }
      let_it_be(:hidden_package) { create(:generic_package, project: disabled_project) }
      let_it_be(:user) { create(:user) }

      before_all do
        group.add_reporter(user)
      end

      subject { get api(url, user) }

      it 'does not return packages from the registry-disabled project' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(visible_package.id)
      end
    end

    context 'when group permission gates listing of descendant project packages' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:subproject) { create(:project, :private, group: group) }
      let_it_be(:package) { create(:generic_package, project: subproject) }

      let_it_be(:granular_assignable_permission_name) do
        ::Authz::PermissionGroups::Assignable.for_permission(:read_package).first.name
      end

      let_it_be(:granular_boundary) { ::Authz::Boundary.for(group) }

      let(:url) { "/groups/#{group.id}/packages" }

      subject(:list_request) { get api(url, user) }

      context 'when caller is Guest on group and Owner on subproject' do
        let_it_be(:user) do
          create(:user).tap do |u|
            group.add_guest(u)
            subproject.add_owner(u)
          end
        end

        context 'with allow_guest_plus_roles_to_pull_packages disabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'returns 200 with the subproject package' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package.id)
          end
        end

        context 'with allow_guest_plus_roles_to_pull_packages enabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: true)
          end

          it 'returns 200 with the subproject package' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package.id)
          end
        end
      end

      context 'with a subgroup' do
        let_it_be(:subgroup) { create(:group, :private, parent: group) }
        let_it_be(:subproject) { create(:project, :private, group: subgroup) }
        let_it_be(:package) { create(:generic_package, project: subproject) }

        context 'when caller is Guest on group + Reporter on the subgroup project' do
          let_it_be(:user) do
            create(:user).tap do |u|
              group.add_guest(u)
              subproject.add_reporter(u)
            end
          end

          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'returns 200 with the subgroup project package' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package.id)
          end

          it 'returns 200 with empty body when exclude_subgroups=true' do
            get api("#{url}?exclude_subgroups=true", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq([])
          end
        end

        context 'when the endpoint is called on the subgroup itself' do
          let_it_be(:user) do
            create(:user).tap do |u|
              group.add_guest(u)
              subproject.add_owner(u)
            end
          end

          let(:url) { "/groups/#{subgroup.id}/packages" }

          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'returns 200 with the subgroup project package' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package.id)
          end
        end
      end

      context 'when caller is an authenticated non-member of a private group' do
        let_it_be(:user) { create(:user) }

        it 'returns 404 because the user cannot read the group' do
          list_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when caller is non-member of the group with Reporter on a subproject' do
        let_it_be(:user) do
          create(:user).tap { |u| subproject.add_reporter(u) }
        end

        it 'returns 200 with the subproject package' do
          list_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to contain_exactly(package.id)
        end

        it 'avoids N+1 queries as packages are added to the subproject' do
          create(:generic_package, project: subproject)

          control = ActiveRecord::QueryRecorder.new do
            get api(url, user)
          end

          create_list(:generic_package, 4, project: subproject)

          expect do
            get api(url, user)
          end.not_to exceed_query_limit(control)
        end

        context 'with a granular PAT scoped to the group with :read_package' do
          let_it_be(:pat) do
            create(:granular_pat,
              user: user,
              boundary: granular_boundary,
              permissions: granular_assignable_permission_name)
          end

          subject(:list_request) { get api(url, personal_access_token: pat) }

          it 'returns 404 because the read_group check rejects non-members' do
            list_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when caller is a non-member with Guest on a subproject' do
        let_it_be(:user) do
          create(:user).tap { |u| subproject.add_guest(u) }
        end

        context 'with allow_guest_plus_roles_to_pull_packages disabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'returns 200 with an empty body' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq([])
          end
        end

        context 'with allow_guest_plus_roles_to_pull_packages enabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: true)
          end

          it 'returns 200 with the subproject package' do
            list_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(package.id)
          end
        end
      end

      context 'with a granular PAT, Guest on group + Reporter on subproject' do
        let_it_be(:user) do
          create(:user).tap do |u|
            group.add_guest(u)
            subproject.add_reporter(u)
          end
        end

        let_it_be(:pat) do
          create(:granular_pat,
            user: user,
            boundary: granular_boundary,
            permissions: granular_assignable_permission_name)
        end

        subject(:list_request) { get api(url, personal_access_token: pat) }

        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it 'returns 200 with the subproject package' do
          list_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to contain_exactly(package.id)
        end
      end

      context 'when scaling with subprojects under the group' do
        observed_delta = 5

        def create_subproject_with_package(group, user)
          subproject = create(:project, :private, group: group)
          subproject.add_reporter(user)
          create(:generic_package, project: subproject)
        end

        it 'stays within an observed query-count delta as subprojects are added' do
          user = create(:user)

          create_subproject_with_package(group, user)

          control = ActiveRecord::QueryRecorder.new do
            get api(url, user)
          end

          4.times { create_subproject_with_package(group, user) }

          expect do
            get api(url, user)
          end.not_to exceed_query_limit(control.count + observed_delta)
        end
      end

      context 'with unrelated groups present' do
        let_it_be(:unrelated_group) { create(:group, :private) }
        let_it_be(:unrelated_project) { create(:project, :private, group: unrelated_group) }
        let_it_be(:unrelated_package) { create(:generic_package, project: unrelated_project) }
        let_it_be(:user) do
          create(:user).tap { |u| group.add_guest(u) }
        end

        it 'does not include packages from unrelated groups' do
          list_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).not_to include(unrelated_package.id)
        end
      end

      context 'with a project shared into the group via project_group_link' do
        let_it_be(:other_group) { create(:group, :private) }
        let_it_be(:shared_project) { create(:project, :private, group: other_group) }
        let_it_be(:package) { create(:generic_package, project: shared_project) }
        let_it_be(:link) do
          create(:project_group_link, project: shared_project, group: group)
        end

        let_it_be(:user) do
          create(:user).tap { |u| shared_project.add_reporter(u) }
        end

        it 'returns 404 because :read_group is not granted via shared-into projects' do
          list_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
