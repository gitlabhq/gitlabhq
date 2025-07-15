# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Projects, :aggregate_failures, feature_category: :groups_and_projects do
  include ProjectForksHelper
  include WorkhorseHelpers
  include StubRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project, reload: true) { create(:project, :repository, create_branch: 'something_else', namespace: user.namespace, updated_at: 5.days.ago) }
  let_it_be(:project2, reload: true) { create(:project, namespace: user.namespace, updated_at: 4.days.ago) }
  let_it_be(:project_member) { create(:project_member, :developer, user: user3, project: project) }
  let_it_be(:user4) { create(:user, username: 'user.withdot') }
  let_it_be(:project3, reload: true) do
    create(
      :project,
      :private,
      :repository,
      creator_id: user.id,
      namespace: user.namespace,
      merge_requests_enabled: false,
      issues_enabled: false, wiki_enabled: false,
      builds_enabled: false,
      snippets_enabled: false
    )
  end

  let_it_be(:project_member2) do
    create(
      :project_member,
      user: user4,
      project: project3,
      access_level: ProjectMember::MAINTAINER
    )
  end

  let_it_be(:project4, reload: true) do
    create(:project, creator_id: user4.id, namespace: user4.namespace)
  end

  let(:user_projects) { [public_project, project, project2, project3] }

  shared_context 'with language detection' do
    let(:ruby) { create(:programming_language, name: 'Ruby') }
    let(:javascript) { create(:programming_language, name: 'JavaScript') }
    let(:html) { create(:programming_language, name: 'HTML') }

    let(:mock_repo_languages) do
      {
        project => { ruby => 0.5, html => 0.5 },
        project3 => { html => 0.7, javascript => 0.3 }
      }
    end

    before do
      mock_repo_languages.each do |proj, lang_shares|
        lang_shares.each do |lang, share|
          create(:repository_language, project: proj, programming_language: lang, share: share)
        end
      end
    end
  end

  shared_examples 'languages and percentages JSON response' do
    let(:expected_languages) { project.repository.languages.to_h { |language| language.values_at(:label, :value) } }

    before do
      allow(project.repository).to receive(:languages).and_return(
        [{ value: 66.69, label: "Ruby", color: "#701516", highlight: "#701516" },
         { value: 22.98, label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a" },
         { value: 7.91, label: "HTML", color: "#e34c26", highlight: "#e34c26" },
         { value: 2.42, label: "CoffeeScript", color: "#244776", highlight: "#244776" }]
      )
    end

    context "when the languages haven't been detected yet" do
      it 'returns expected language values', :aggregate_failures, :sidekiq_might_not_need_inline do
        get api("/projects/#{project.id}/languages", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({})

        get api("/projects/#{project.id}/languages", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(expected_languages)
      end
    end

    context 'when the languages were detected before' do
      before do
        Projects::DetectRepositoryLanguagesService.new(project, project.first_owner).execute
      end

      it 'returns the detection from the database', :aggregate_failures do
        # Allow this to happen once, so the expected languages can be determined
        expect(project.repository).to receive(:languages).once

        get api("/projects/#{project.id}/languages", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(expected_languages)
        expect(json_response.count).to be > 1
      end
    end
  end

  shared_examples_for 'create project with default branch parameter' do
    let(:params) { { name: 'Foo Project', initialize_with_readme: true, default_branch: default_branch } }
    let(:default_branch) { 'main' }

    it 'creates project with provided default branch name' do
      expect { request }.to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.find(json_response['id'])
      expect(project.default_branch).to eq(default_branch)
    end

    context 'when branch name is empty' do
      let(:default_branch) { '' }

      it 'creates project with a default project branch name' do
        expect { request }.to change { Project.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)

        project = Project.find(json_response['id'])
        expect(project.default_branch).to eq('master')
      end
    end

    context 'when initialize with readme is not set' do
      let(:params) { super().merge(initialize_with_readme: nil) }

      it 'creates project with a default project branch name' do
        expect { request }.to change { Project.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)

        project = Project.find(json_response['id'])
        expect(project.default_branch).to be_nil
      end
    end
  end

  describe 'GET /projects' do
    let(:path) { '/projects' }

    let_it_be(:public_project) { create(:project, :public, name: 'public_project') }

    shared_examples_for 'projects response' do
      let_it_be(:admin_mode) { false }

      it 'returns an array of projects' do
        get api(path, current_user, admin_mode: admin_mode), params: filter

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(*projects.map(&:id))
      end

      it 'returns the proper security headers' do
        get api(path, current_user, admin_mode: admin_mode), params: filter

        expect(response).to include_security_headers
      end
    end

    shared_examples_for 'projects response without N + 1 queries' do |threshold|
      let(:additional_project) { create(:project, :public) }

      it 'avoids N + 1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api(path, current_user)
        end

        additional_project

        expect do
          get api(path, current_user)
        end.not_to exceed_all_query_limit(control).with_threshold(threshold)
      end
    end

    shared_examples_for 'filtering by topic (column topic_list)' do
      let(:project_with_topics) { nil }

      before do
        project_with_topics.update!(topic_list: %w[ruby javascript])
      end

      it 'returns no projects' do
        get api(path, user), params: { topic: 'foo' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end

      it 'returns matching project for a single topic' do
        get api(path, user), params: { topic: 'ruby' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to contain_exactly a_hash_including('id' => project_with_topics.id)
      end

      it 'returns matching project for multiple topics' do
        get api(path, user), params: { topic: 'ruby, javascript' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to contain_exactly a_hash_including('id' => project_with_topics.id)
      end

      it 'returns no projects if project match only some topic' do
        get api(path, user), params: { topic: 'ruby, foo' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_empty
      end

      it 'ignores topic if it is empty' do
        get api(path, user), params: { topic: '' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_present
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'projects response' do
        let(:filter) { { search: project.path } }
        let(:current_user) { user }
        let(:projects) { [project] }
      end

      it_behaves_like 'projects response without N + 1 queries', 1 do
        let(:current_user) { nil }
      end

      it_behaves_like 'filtering by topic (column topic_list)' do
        let(:user) { nil }
        let(:current_user) { nil }
        let(:namespace) { create(:namespace) }
        let(:project_with_topics) do
          create(:project, :repository, :public, namespace: namespace, updated_at: 5.days.ago)
        end

        before do
          allow(Organizations::Organization).to(
            receive(:default_organization).and_return(namespace.organization)
          )
        end
      end
    end

    context 'when authenticated as regular user' do
      it_behaves_like 'projects response' do
        let(:filter) { {} }
        let(:current_user) { user }
        let(:projects) { user_projects }
      end

      it_behaves_like 'projects response without N + 1 queries', 0 do
        let(:current_user) { user }
      end

      it_behaves_like 'filtering by topic (column topic_list)' do
        let(:project_with_topics) do
          create(:project, :repository, namespace: user.namespace, updated_at: 5.days.ago)
        end
      end

      context 'when filtering by active parameter' do
        let_it_be(:marked_for_deletion_project) do
          create(:project, marked_for_deletion_on: Date.parse('2024-01-01'), namespace: user.namespace)
        end

        let_it_be(:archived_project) do
          create(:project, :archived, namespace: user.namespace)
        end

        context 'when active is true' do
          it 'returns only non archived and not marked for deletion projects' do
            get api(path, user), params: { active: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.map { |p| p['id'] }).not_to include(archived_project.id, marked_for_deletion_project.id)
          end
        end

        context 'when active is false' do
          it 'returns only archived or marked for deletion projects' do
            get api(path, user), params: { active: false }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.map { |p| p['id'] }).to contain_exactly(archived_project.id, marked_for_deletion_project.id)
          end
        end
      end

      shared_examples 'includes container_registry_access_level' do
        specify do
          project.project_feature.update!(container_registry_access_level: ProjectFeature::DISABLED)

          get api(path, user)
          project_response = json_response.find { |p| p['id'] == project.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(project_response['container_registry_access_level']).to eq('disabled')
          expect(project_response['container_registry_enabled']).to eq(false)
        end
      end

      include_examples 'includes container_registry_access_level'

      it 'includes various project feature fields' do
        get api(path, user)
        project_response = json_response.find { |p| p['id'] == project.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(project_response['releases_access_level']).to eq('enabled')
        expect(project_response['environments_access_level']).to eq('enabled')
        expect(project_response['feature_flags_access_level']).to eq('enabled')
        expect(project_response['infrastructure_access_level']).to eq('enabled')
        expect(project_response['monitor_access_level']).to eq('enabled')
      end

      context 'when some projects are in a group' do
        before do
          create(:project, :public, group: create(:group))
        end

        it_behaves_like 'projects response without N + 1 queries', 1 do
          let(:current_user) { user }
          let(:additional_project) { create(:project, :public, group: create(:group)) }
        end
      end

      context 'when projects is in a subgroup' do
        let_it_be(:group) { create(:group) }
        let_it_be(:group_member) { create(:group_member, :developer, group: group, user: user) }

        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project) { create(:project, group: subgroup) }

        before do
          get api(path, user)
        end

        it_behaves_like 'projects response without N + 1 queries', 1 do
          let(:current_user) { user }
          let(:additional_project) { project }
        end

        it 'returns the correct group access', :aggregate_failures do
          project_response = json_response.find { |p| p['id'] == project.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(project_response['permissions']['group_access']['access_level'])
            .to eq(Gitlab::Access::DEVELOPER)
        end

        context 'when user has multiple group membership' do
          let_it_be(:subgroup_member) { create(:group_member, :owner, group: subgroup, user: user) }

          it 'returns the highest access level', :aggregate_failures do
            project_response = json_response.find { |p| p['id'] == project.id }

            expect(response).to have_gitlab_http_status(:ok)
            expect(project_response['permissions']['group_access']['access_level'])
              .to eq(Gitlab::Access::OWNER)
          end
        end
      end

      it 'includes correct value of container_registry_enabled' do
        project.project_feature.update!(container_registry_access_level: ProjectFeature::DISABLED)

        get api(path, user)
        project_response = json_response.find { |p| p['id'] == project.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(project_response['container_registry_enabled']).to eq(false)
      end

      it 'includes project topics' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include('tag_list') # deprecated in favor of 'topics'
        expect(json_response.first.keys).to include('topics')
      end

      it 'includes open_issues_count' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include('open_issues_count')
      end

      it 'does not include projects marked for deletion' do
        project.update!(pending_delete: true)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).not_to include(project.id)
      end

      context 'when user requests pending_delete projects' do
        before do
          project.update!(pending_delete: true)
        end

        let(:params) { { include_pending_delete: true } }

        it 'does not return projects marked for deletion' do
          get api(path, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).not_to include(project.id)
        end

        context 'when user is an admin' do
          it 'returns projects marked for deletion' do
            get api(path, admin, admin_mode: true), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.map { |p| p['id'] }).to include(project.id)
          end
        end
      end

      it 'does not include open_issues_count if issues are disabled' do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.find { |hash| hash['id'] == project.id }.keys).not_to include('open_issues_count')
      end

      context 'filter by topic_id' do
        let_it_be(:topic1) { create(:topic, organization_id: project.organization_id) }
        let_it_be(:topic2) { create(:topic, organization_id: project.organization_id) }

        let(:current_user) { user }

        before do
          project.topics << topic1
        end

        context 'with id of assigned topic' do
          it_behaves_like 'projects response' do
            let(:filter) { { topic_id: topic1.id } }
            let(:projects) { [project] }
          end
        end

        context 'with id of unassigned topic' do
          it_behaves_like 'projects response' do
            let(:filter) { { topic_id: topic2.id } }
            let(:projects) { [] }
          end
        end

        context 'with non-existing topic id' do
          it_behaves_like 'projects response' do
            let(:filter) { { topic_id: non_existing_record_id } }
            let(:projects) { [] }
          end
        end

        context 'with empty topic id' do
          it_behaves_like 'projects response' do
            let(:filter) { { topic_id: '' } }
            let(:projects) { user_projects }
          end
        end
      end

      context 'and with_issues_enabled=true' do
        it 'only returns projects with issues enabled' do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get api('/projects?with_issues_enabled=true', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).not_to include(project.id)
        end
      end

      it "does not include statistics by default" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes statistics if requested" do
        get api(path, user), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        statistics = json_response.find { |p| p['id'] == project.id }['statistics']
        expect(statistics).to be_present
        expect(statistics).to include('commit_count', 'storage_size', 'repository_size', 'wiki_size', 'lfs_objects_size', 'job_artifacts_size', 'pipeline_artifacts_size', 'snippets_size', 'packages_size', 'uploads_size', 'container_registry_size')
      end

      it "does not include license by default" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('license', 'license_url')
      end

      it "does not include license if requested" do
        get api(path, user), params: { license: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('license', 'license_url')
      end

      context 'when external issue tracker is enabled' do
        let!(:jira_integration) { create(:jira_integration, project: project) }

        it 'includes open_issues_count' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first.keys).to include('open_issues_count')
          expect(json_response.find { |hash| hash['id'] == project.id }.keys).to include('open_issues_count')
        end

        it 'does not include open_issues_count if issues are disabled' do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.find { |hash| hash['id'] == project.id }.keys).not_to include('open_issues_count')
        end
      end

      context 'and with simple=true' do
        it 'returns a simplified version of all the projects' do
          get api('/projects?simple=true', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(response).to match_response_schema('public_api/v4/projects')
        end
      end

      context 'and using archived' do
        let!(:archived_project) { create(:project, creator_id: user.id, namespace: user.namespace, archived: true) }

        it 'returns archived projects' do
          get api('/projects?archived=true', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user).where(archived: true).size)
          expect(json_response.map { |project| project['id'] }).to include(archived_project.id)
        end

        it 'returns non-archived projects' do
          get api('/projects?archived=false', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user).where(archived: false).size)
          expect(json_response.map { |project| project['id'] }).not_to include(archived_project.id)
        end

        it 'returns every project' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(*Project.public_or_visible_to_user(user).pluck(:id))
        end
      end

      context 'filter by updated_at' do
        let(:filter) { { updated_before: 2.days.ago.iso8601, updated_after: 6.days.ago, order_by: :updated_at } }

        it_behaves_like 'projects response' do
          let(:current_user) { user }
          let(:projects) { [project2, project] }
        end

        it 'returns projects sorted by updated_at' do
          get api(path, user), params: filter

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.map { |p| p['id'] }).to match([project2, project].map(&:id))
        end

        context 'when filtering by updated_at and sorting by a different column' do
          let(:filter) { { updated_before: 2.days.ago.iso8601, updated_after: 6.days.ago, order_by: 'id' } }

          it 'returns an error' do
            get api(path, user), params: filter

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq(
              '400 Bad request - `updated_at` filter and `updated_at` sorting must be paired'
            )
          end
        end
      end

      context 'and using search' do
        it_behaves_like 'projects response' do
          let(:filter) { { search: project.path } }
          let(:current_user) { user }
          let(:projects) { [project] }
        end
      end

      context 'and using search and search_namespaces is true' do
        let(:group) { create(:group) }
        let!(:project_in_group) { create(:project, group: group) }

        before do
          group.add_guest(user)
        end

        it_behaves_like 'projects response' do
          let(:filter) { { search: group.name, search_namespaces: true } }
          let(:current_user) { user }
          let(:projects) { [project_in_group] }
        end
      end

      context 'and using id_after' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_after: project2.id } }
          let(:current_user) { user }
          let(:projects) { user_projects.select { |p| p.id > project2.id } }
        end

        context 'regression: empty string is ignored' do
          it_behaves_like 'projects response' do
            let(:filter) { { id_after: '' } }
            let(:current_user) { user }
            let(:projects) { user_projects }
          end
        end
      end

      context 'and using id_before' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_before: project2.id } }
          let(:current_user) { user }
          let(:projects) { user_projects.select { |p| p.id < project2.id } }
        end

        context 'regression: empty string is ignored' do
          it_behaves_like 'projects response' do
            let(:filter) { { id_before: '' } }
            let(:current_user) { user }
            let(:projects) { user_projects }
          end
        end
      end

      context 'and using both id_after and id_before' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_before: project2.id, id_after: public_project.id } }
          let(:current_user) { user }
          let(:projects) { user_projects.select { |p| p.id < project2.id && p.id > public_project.id } }
        end
      end

      context 'and membership=true' do
        it_behaves_like 'projects response' do
          let(:filter) { { membership: true } }
          let(:current_user) { user }
          let(:projects) { [project, project2, project3] }
        end
      end

      context 'and using the visibility filter' do
        it 'filters based on private visibility param' do
          get api(path, user), params: { visibility: 'private' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id, project2.id, project3.id)
        end

        it 'filters based on internal visibility param' do
          project2.update_attribute(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)

          get api(path, user), params: { visibility: 'internal' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project2.id)
        end

        it 'filters based on public visibility param' do
          get api(path, user), params: { visibility: 'public' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(public_project.id)
        end
      end

      context 'and using the programming language filter' do
        include_context 'with language detection'

        it 'filters case-insensitively by programming language' do
          get api(path, user), params: { with_programming_language: 'javascript' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project3.id)
        end
      end

      context 'and using sorting' do
        it 'returns the correct order when sorted by id' do
          get api(path, user), params: { order_by: 'id', sort: 'desc' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to eq(user_projects.map(&:id).sort.reverse)
        end
      end

      context 'and with owned=true' do
        it 'returns an array of projects the user owns' do
          get api(path, user4), params: { owned: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['name']).to eq(project4.name)
          expect(json_response.first['owner']['username']).to eq(user4.username)
        end

        context 'when admin creates a project' do
          before do
            group = create(:group)
            project_create_opts = {
              name: 'GitLab',
              namespace_id: group.id
            }

            Projects::CreateService.new(admin, project_create_opts).execute
          end

          it 'does not list as owned project for admin' do
            get api(path, admin, admin_mode: true), params: { owned: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_empty
          end
        end
      end

      context 'and with starred=true' do
        let(:public_project) { create(:project, :public) }

        before do
          user3.update!(starred_projects: [project, project2, project3, public_project])
        end

        it 'returns the starred projects viewable by the user' do
          get api(path, user3), params: { starred: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(project.id, public_project.id)
        end
      end

      context 'and with all query parameters' do
        let!(:project5) { create(:project, :public, path: 'gitlab5', namespace: create(:namespace)) }
        let!(:project6) { create(:project, :public, namespace: user.namespace) }
        let!(:project7) { create(:project, :public, path: 'gitlab7', namespace: user.namespace) }
        let!(:project8) { create(:project, path: 'gitlab8', namespace: user.namespace) }
        let!(:project9) { create(:project, :public, path: 'gitlab9') }

        before do
          [project5, project7, project8, project9].each do |project|
            user.users_star_projects.create!(project_id: project.id)
          end
        end

        context 'including owned filter' do
          it 'returns only projects that satisfy all query parameters' do
            get api(path, user), params: { visibility: 'public', owned: true, starred: true, search: 'gitlab' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(1)
            expect(json_response.first['id']).to eq(project7.id)
          end
        end

        context 'including membership filter' do
          before do
            create(:project_member, user: user, project: project5, access_level: ProjectMember::MAINTAINER)
          end

          it 'returns only projects that satisfy all query parameters' do
            get api(path, user), params: { visibility: 'public', membership: true, starred: true, search: 'gitlab' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(2)
            expect(json_response.map { |project| project['id'] }).to contain_exactly(project5.id, project7.id)
          end
        end
      end

      context 'and with min_access_level' do
        before do
          project2.add_maintainer(user2)
          project3.add_developer(user2)
          project4.add_reporter(user2)
        end

        it 'returns an array of projects the user has at least developer access' do
          get api(path, user2), params: { min_access_level: 30 }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(project2.id, project3.id)
        end
      end
    end

    context 'and imported=true' do
      before do
        other_user = create(:user)
        # imported project by other user
        create(:project, creator: other_user, import_type: 'github', import_url: 'http://foo.com')
        # project created by current user directly instead of importing
        create(:project)
        project.update_attribute(:import_url, 'http://user:password@host/path')
        project.update_attribute(:import_type, 'github')
      end

      it 'returns only imported projects owned by current user' do
        get api('/projects?imported=true', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to eq [project.id]
      end

      it 'does not expose import credentials' do
        get api('/projects?imported=true', user)

        expect(json_response.first['import_url']).to eq 'http://host/path'
      end
    end

    context 'when authenticated as a different user' do
      it_behaves_like 'projects response' do
        let(:filter) { {} }
        let(:current_user) { user2 }
        let(:projects) { [public_project] }
      end

      context 'and with_issues_enabled=true' do
        it 'does not return private issue projects' do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)

          get api('/projects?with_issues_enabled=true', user2)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).not_to include(project.id)
        end
      end
    end

    context 'when authenticated as admin' do
      it_behaves_like 'projects response' do
        let(:filter) { {} }
        let(:current_user) { admin }
        let(:admin_mode) { true }
        let(:projects) { Project.all }
      end

      it 'returns a project with user namespace that has a missing owner' do
        project.namespace.update_column(:owner_id, non_existing_record_id)
        project.route.update_column(:name, nil)

        get api(path, admin, admin_mode: true), params: { search: project.path }
        expect(response).to have_gitlab_http_status(:ok)

        project_response = json_response.find { |p| p['id'] == project.id }
        expect(project_response).to be_present
        expect(project_response['path']).to eq(project.path)

        namespace_response = project_response['namespace']
        expect(project_response['web_url']).to include(namespace_response['web_url'])
      end
    end

    context 'with default created_at desc order' do
      let_it_be(:group_with_projects) { create(:group) }
      let_it_be(:project_1) { create(:project, name: 'Project 1', created_at: 3.days.ago, path: 'project1', group: group_with_projects) }
      let_it_be(:project_2) { create(:project, name: 'Project 2', created_at: 2.days.ago, path: 'project2', group: group_with_projects) }
      let_it_be(:project_3) { create(:project, name: 'Project 3', created_at: 1.day.ago, path: 'project3', group: group_with_projects) }

      let(:current_user) { user }
      let(:params) { {} }

      subject(:request) { get api(path, current_user), params: params }

      before do
        group_with_projects.add_owner(current_user) if current_user
      end

      it 'orders by id desc instead' do
        projects_ordered_by_id_desc = /SELECT "projects".+ORDER BY "projects"."id" DESC/i
        expect { request }.to make_queries_matching projects_ordered_by_id_desc

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(project_3.id)
      end
    end

    context 'sorting' do
      context 'by star_count' do
        let_it_be(:project_most_stars) { create(:project, :public, star_count: 100) }
        let_it_be(:project_no_stars) { create(:project, :public, star_count: 0) }
        let_it_be(:project_few_stars) { create(:project, :public, star_count: 10) }

        it 'with order_by=star_count, returns list of projects sorted by star_count descending' do
          get api(path), params: { order_by: 'star_count' }

          expected_order = [project_most_stars, project_few_stars, project_no_stars, public_project]

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |x| x['id'] }).to eq(expected_order.map(&:id))
        end
      end

      context 'by project statistics' do
        %w[repository_size storage_size wiki_size packages_size].each do |order_by|
          context "sorting by #{order_by}" do
            before do
              ProjectStatistics.update_all(order_by => 100)
              project4.statistics.update_columns(order_by => 10)
              project.statistics.update_columns(order_by => 200)
            end

            context 'admin user' do
              let(:current_user) { admin }

              context "when sorting by #{order_by} ascendingly" do
                it 'returns a properly sorted list of projects' do
                  get api(path, current_user, admin_mode: true), params: { order_by: order_by, sort: :asc }

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response).to include_pagination_headers
                  expect(json_response).to be_an Array
                  expect(json_response.first['id']).to eq(project4.id)
                end
              end

              context "when sorting by #{order_by} descendingly" do
                it 'returns a properly sorted list of projects' do
                  get api(path, current_user, admin_mode: true), params: { order_by: order_by, sort: :desc }

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response).to include_pagination_headers
                  expect(json_response).to be_an Array
                  expect(json_response.first['id']).to eq(project.id)
                end
              end
            end

            context 'non-admin user' do
              let(:current_user) { user }

              it 'returns projects ordered normally' do
                get api(path, current_user), params: { order_by: order_by }

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers
                expect(json_response).to be_an Array
                expect(json_response.map { |project| project['id'] }).to eq(user_projects.map(&:id).sort.reverse)
              end
            end
          end
        end
      end

      context 'by similarity' do
        let_it_be(:group_with_projects) { create(:group) }
        let_it_be(:project_1) { create(:project, name: 'Project', path: 'project', group: group_with_projects) }
        let_it_be(:project_2) { create(:project, name: 'Test Project', path: 'test-project', group: group_with_projects) }
        let_it_be(:project_3) { create(:project, name: 'Test', path: 'test', group: group_with_projects) }
        let_it_be(:project_4) { create(:project, :public, name: 'Test Public Project') }

        let(:current_user) { user }
        let(:params) { { order_by: 'similarity', search: 'test' } }

        subject(:request) { get api(path, current_user), params: params }

        before do
          group_with_projects.add_owner(current_user) if current_user
        end

        it 'returns non-public items based ordered by similarity' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(2)

          project_names = json_response.map { |proj| proj['name'] }
          expect(project_names).to contain_exactly('Test', 'Test Project')
        end

        context 'when `search` parameter is not given' do
          let(:params) { { order_by: 'similarity' } }

          it 'returns items ordered by created_at descending' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(8)

            project_names = json_response.map { |proj| proj['name'] }
            expect(project_names).to match_array([project, project2, project3, public_project, project_1, project_2, project_4, project_3].map(&:name))
          end
        end

        context 'when called anonymously' do
          let(:current_user) { nil }

          it 'returns items ordered by created_at descending' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(1)

            project_names = json_response.map { |proj| proj['name'] }
            expect(project_names).to contain_exactly(project_4.name)
          end
        end
      end
    end

    context 'when using the marked_for_deletion_on filter' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group, owners: user) }
      let_it_be(:marked_for_deletion_project) do
        create(:project, marked_for_deletion_at: Date.parse('2024-01-01'), group: group)
      end

      it 'returns groups marked for deletion on the specified date' do
        get api("/projects", user), params: { marked_for_deletion_on: Date.parse('2024-01-01') }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project["id"] }).to contain_exactly(marked_for_deletion_project.id)
        expect(json_response.map { |project| project["marked_for_deletion_on"] }).to contain_exactly(Date.parse('2024-01-01').iso8601)
      end

      it 'returns all projects when marked_for_deletion_on is not specified' do
        get api("/projects", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project["id"] }).to contain_exactly(public_project.id, marked_for_deletion_project.id)
      end
    end

    context 'filtering by repository_storage' do
      before do
        [project, project3].each { |proj| proj.update_columns(repository_storage: 'nfs-11') }
        # Since we don't actually have Gitaly configured with an nfs-11 storage, an error would be raised
        # when we present the projects in a response, as we ask Gitaly for stuff like default branch and Gitaly
        # is not configured for a nfs-11 storage. So we trick Rails into thinking the storage for these projects
        # is still default (in reality, it is).
        allow_any_instance_of(Project).to receive(:repository_storage).and_return('default')
      end

      context 'admin user' do
        it_behaves_like 'projects response' do
          let(:filter) { { repository_storage: 'nfs-11' } }
          let(:current_user) { admin }
          let(:admin_mode) { true }
          let(:projects) { [project, project3] }
        end
      end

      context 'non-admin user' do
        it_behaves_like 'projects response' do
          let(:filter) { { repository_storage: 'nfs-11' } }
          let(:current_user) { user }
          let(:projects) { [public_project, project, project2, project3] }
        end
      end
    end

    context 'with keyset pagination' do
      let(:current_user) { user }
      let(:first_project_id) { user_projects.map(&:id).min }
      let(:last_project_id) { user_projects.map(&:id).max }

      context 'headers and records' do
        let(:params) { { pagination: 'keyset', order_by: :id, sort: :asc, per_page: 1 } }

        it 'includes a pagination header with link to the next page' do
          get api(path, current_user), params: params

          expect(response.header).to include('Link')
          expect(response.header['Link']).to include('pagination=keyset')
          expect(response.header['Link']).to include("id_after=#{first_project_id}")
        end

        it 'contains only the first project with per_page = 1' do
          get api(path, current_user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(first_project_id)
        end

        it 'still includes a link if the end has reached and there is no more data after this page' do
          get api(path, current_user), params: params.merge(id_after: project2.id)

          expect(response.header).to include('Link')
          expect(response.header['Link']).to include('pagination=keyset')
          expect(response.header['Link']).to include("id_after=#{project3.id}")
        end

        it 'does not include a next link when the page does not have any records' do
          get api(path, current_user), params: params.merge(id_after: Project.maximum(:id))

          expect(response.header).not_to include('Link')
        end

        it 'returns an empty array when the page does not have any records' do
          get api(path, current_user), params: params.merge(id_after: Project.maximum(:id))

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq([])
        end

        it 'responds with 501 if order_by is different from id' do
          get api(path, current_user), params: params.merge(order_by: :created_at)

          expect(response).to have_gitlab_http_status(:method_not_allowed)
        end
      end

      context 'with descending sorting' do
        let(:params) { { pagination: 'keyset', order_by: :id, sort: :desc, per_page: 1 } }

        it 'includes a pagination header with link to the next page' do
          get api(path, current_user), params: params

          expect(response.header).to include('Link')
          expect(response.header['Link']).to include('pagination=keyset')
          expect(response.header['Link']).to include("id_before=#{last_project_id}")
        end

        it 'contains only the last project with per_page = 1' do
          get api(path, current_user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(last_project_id)
        end
      end

      context 'retrieving the full relation' do
        let(:params) { { pagination: 'keyset', order_by: :id, sort: :desc, per_page: 2 } }

        it 'returns all projects' do
          url = path
          requests = 0
          ids = []

          while url && requests <= 5 # circuit breaker
            requests += 1
            get api(url, current_user), params: params

            link = response.header['Link']
            url = link&.match(%r{<[^>]+(/projects\?[^>]+)>; rel="next"}) do |match|
              match[1]
            end

            ids += Gitlab::Json.parse(response.body).map { |p| p['id'] }
          end

          expect(ids).to contain_exactly(*user_projects.map(&:id))
        end
      end
    end

    context 'with forked projects', :use_clean_rails_memory_store_caching do
      include ProjectForksHelper

      let_it_be(:admin) { create(:admin) }

      subject(:request) { get api(path, admin) }

      it 'avoids N+1 queries', :use_sql_query_cache do
        request
        expect(response).to have_gitlab_http_status(:ok)

        base_project = create(:project, :public, namespace: admin.namespace)

        fork_project1 = fork_project(base_project, admin, namespace: create(:user).namespace)
        fork_project2 = fork_project(fork_project1, admin, namespace: create(:user).namespace)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          request
        end

        fork_project(fork_project2, admin, namespace: create(:user).namespace)

        expect do
          request
        end.not_to exceed_all_query_limit(control)
      end
    end

    context 'when service desk is enabled', :use_clean_rails_memory_store_caching do
      let_it_be(:admin) { create(:admin) }

      subject(:request) { get api(path, admin) }

      it 'avoids N+1 queries' do
        allow(Gitlab::Email::ServiceDeskEmail).to receive(:enabled?).and_return(true)
        allow(Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)

        request
        expect(response).to have_gitlab_http_status(:ok)

        create(:project, :public, :service_desk_enabled, namespace: admin.namespace)

        control = ActiveRecord::QueryRecorder.new do
          request
        end

        create_list(:project, 2, :public, :service_desk_enabled, namespace: admin.namespace)

        expect do
          request
        end.not_to exceed_all_query_limit(control)
      end
    end

    context 'rate limiting' do
      let_it_be(:current_user) { create(:user) }

      context 'when the user is signed in' do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :projects_api do
          def request
            get api(path, current_user)
          end
        end
      end

      context 'when the user is not signed in' do
        let_it_be(:current_user) { nil }

        it_behaves_like 'rate limited endpoint', rate_limit_key: :projects_api_rate_limit_unauthenticated do
          def request
            get api(path, current_user)
          end
        end
      end
    end
  end

  describe 'POST /projects' do
    let(:path) { '/projects' }

    context 'maximum number of projects reached' do
      it 'does not create new project and respond with 403' do
        allow_any_instance_of(User).to receive(:projects_limit_left).and_return(0)
        expect { post api(path, user2), params: { name: 'foo' } }
          .not_to change { Project.count }
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it 'creates new project without path but with name and returns 201' do
      expect { post api(path, user), params: { name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.last

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project without name but with path and returns 201' do
      expect { post api(path, user), params: { path: 'foo_project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.last

      expect(project.name).to eq('foo_project')
      expect(project.path).to eq('foo_project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api(path, user), params: { path: 'path-project-Foo', name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.last

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('path-project-Foo')
    end

    it_behaves_like 'create project with default branch parameter' do
      subject(:request) { post api(path, user), params: params }
    end

    it 'creates last project before reaching project limit' do
      allow_any_instance_of(User).to receive(:projects_limit_left).and_return(1)
      post api(path, user2), params: { name: 'foo' }
      expect(response).to have_gitlab_http_status(:created)
    end

    it 'does not create new project without name or path and returns 400' do
      expect { post api(path, user) }.not_to change { Project.count }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'assigns attributes to project' do
      project = attributes_for(:project, {
        path: 'camelCasePath',
        issues_enabled: false,
        jobs_enabled: false,
        merge_requests_enabled: false,
        forking_access_level: 'disabled',
        analytics_access_level: 'disabled',
        wiki_enabled: false,
        resolve_outdated_diff_discussions: false,
        remove_source_branch_after_merge: true,
        autoclose_referenced_issues: true,
        only_allow_merge_if_pipeline_succeeds: true,
        allow_merge_on_skipped_pipeline: true,
        request_access_enabled: true,
        only_allow_merge_if_all_discussions_are_resolved: false,
        ci_config_path: 'a/custom/path',
        merge_method: 'ff',
        squash_option: 'always'
      }).tap do |attrs|
        attrs[:analytics_access_level] = 'disabled'
        attrs[:container_registry_access_level] = 'private'
        attrs[:security_and_compliance_access_level] = 'private'
        attrs[:releases_access_level] = 'disabled'
        attrs[:environments_access_level] = 'disabled'
        attrs[:feature_flags_access_level] = 'disabled'
        attrs[:infrastructure_access_level] = 'disabled'
        attrs[:monitor_access_level] = 'disabled'
        attrs[:snippets_access_level] = 'disabled'
        attrs[:wiki_access_level] = 'disabled'
        attrs[:builds_access_level] = 'disabled'
        attrs[:merge_requests_access_level] = 'disabled'
        attrs[:issues_access_level] = 'disabled'
        attrs[:model_experiments_access_level] = 'disabled'
        attrs[:model_registry_access_level] = 'disabled'
      end

      post api(path, user), params: project

      expect(response).to have_gitlab_http_status(:created)

      project.each_pair do |k, v|
        next if %i[
          has_external_issue_tracker has_external_wiki issues_enabled merge_requests_enabled wiki_enabled storage_version
          container_registry_access_level releases_access_level environments_access_level feature_flags_access_level
          infrastructure_access_level monitor_access_level model_experiments_access_level model_registry_access_level
          namespace
        ].include?(k)

        expect(json_response[k.to_s]).to eq(v)
      end

      # Check feature permissions attributes
      project = Project.find_by_path(project[:path])
      expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.analytics_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.container_registry_access_level).to eq(ProjectFeature::PRIVATE)
      expect(project.project_feature.security_and_compliance_access_level).to eq(ProjectFeature::PRIVATE)
      expect(project.project_feature.releases_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.environments_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.feature_flags_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.infrastructure_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.monitor_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.builds_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.snippets_access_level).to eq(ProjectFeature::DISABLED)

      # Check namespace attributes
      expect(project.namespace.id).to eq(user.namespace.id)
      expect(project.namespace.name).to eq(user.namespace.name)
      expect(project.namespace.path).to eq(user.namespace.path)
      expect(project.namespace.kind).to eq(user.namespace.kind)
      expect(project.namespace.full_path).to eq(user.namespace.full_path)
      expect(project.namespace.parent_id).to be_nil
      expect(project.namespace.avatar_url).to eq(user.namespace.avatar_url)
      expect(project.namespace.web_url).to eq(user.namespace.web_url)
    end

    it 'assigns container_registry_enabled to project' do
      project = attributes_for(:project, { container_registry_enabled: true })

      post api(path, user), params: project

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['container_registry_enabled']).to eq(true)
      expect(json_response['container_registry_access_level']).to eq('enabled')
      expect(Project.find_by(path: project[:path]).container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end

    it 'assigns container_registry_enabled to project' do
      project = attributes_for(:project, { container_registry_enabled: true })

      post api(path, user), params: project

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['container_registry_enabled']).to eq(true)
      expect(Project.find_by(path: project[:path]).container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end

    it 'creates a project using a template' do
      expect { post api(path, user), params: { template_name: 'rails', name: 'rails-test' } }
        .to change { Project.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)

      project = Project.find(json_response['id'])
      expect(project).to be_saved
      expect(project.import_type).to eq('gitlab_built_in_project_template')
    end

    it 'returns 400 for an invalid template' do
      expect { post api(path, user), params: { template_name: 'unknown', name: 'rails-test' } }
        .not_to change { Project.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['template_name']).to eq(["'unknown' is unknown or invalid"])
    end

    it 'disallows creating a project with an import_url and template' do
      project_params = { import_url: 'http://example.com', template_name: 'rails', name: 'rails-test' }
      expect { post api(path, user), params: project_params }
        .not_to change {  Project.count }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'disallows creating a project with an import_url when git import source is disabled' do
      url = 'http://example.com'
      stub_application_setting(import_sources: nil)

      allow(Gitlab::GitalyClient::RemoteService).to receive(:exists?).with(url).and_return(true)

      project_params = { import_url: url, path: 'path-project-Foo', name: 'Foo Project' }
      expect { post api(path, user), params: project_params }
        .not_to change {  Project.count }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'allows creating a project without an import_url when git import source is disabled' do
      stub_application_setting(import_sources: nil)
      project_params = { path: 'path-project-Foo' }

      expect { post api(path, user), params: project_params }.to change { Project.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'creates a project with an import_url that is valid' do
      url = 'http://example.com'

      allow(Gitlab::GitalyClient::RemoteService).to receive(:exists?).with(url).and_return(true)
      stub_application_setting(import_sources: ['git'])

      project_params = { import_url: url, path: 'path-project-Foo', name: 'Foo Project' }

      expect { post api(path, user), params: project_params }.to change { Project.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api(path, user), params: project

      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api(path, user), params: project

      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api(path, user), params: project

      expect(json_response['visibility']).to eq('private')
    end

    it 'creates a new project initialized with a README.md' do
      project = attributes_for(:project, initialize_with_readme: 1)

      post api(path, user), params: project

      expect(json_response['readme_url']).to eql("#{Gitlab.config.gitlab.url}/#{json_response['namespace']['full_path']}/#{json_response['path']}/-/blob/master/README.md")
    end

    it 'sets tag list to a project (deprecated)' do
      project = attributes_for(:project, tag_list: %w[tagFirst tagSecond])

      post api(path, user), params: project

      expect(json_response['topics']).to eq(%w[tagFirst tagSecond])
    end

    it 'sets topics to a project' do
      project = attributes_for(:project, topics: %w[topic1 topics2])

      post api(path, user), params: project

      expect(json_response['topics']).to eq(%w[topic1 topics2])
    end

    it 'uploads avatar for project a project' do
      project = attributes_for(:project, avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif'))

      workhorse_form_with_file(
        api(path, user),
        method: :post,
        file_key: :avatar,
        params: project
      )

      project_id = json_response['id']
      expect(json_response['avatar_url']).to eq("http://localhost/uploads/-/system/project/avatar/#{project_id}/banana_sample.gif")
    end

    it 'sets a project as not allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api(path, user), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api(path, user), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as not removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: false)

      post api(path, user), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_falsey
    end

    it 'sets a project as removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: true)

      post api(path, user), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)

      post api(path, user), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if merge_when_pipeline_succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)

      post api(path, user), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as not allowing merge when pipeline is skipped' do
      project_params = attributes_for(:project, allow_merge_on_skipped_pipeline: false)

      post api(path, user), params: project_params

      expect(json_response['allow_merge_on_skipped_pipeline']).to be_falsey
    end

    it 'sets a project as allowing merge when pipeline is skipped' do
      project_params = attributes_for(:project, allow_merge_on_skipped_pipeline: true)

      post api(path, user), params: project_params

      expect(json_response['allow_merge_on_skipped_pipeline']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api(path, user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge if only_allow_merge_if_all_discussions_are_resolved is nil' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: nil)

      post api(path, user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api(path, user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end

    it 'sets a project as enabling auto close referenced issues' do
      project = attributes_for(:project, autoclose_referenced_issues: true)

      post api(path, user), params: project

      expect(json_response['autoclose_referenced_issues']).to be_truthy
    end

    it 'sets a project as disabling auto close referenced issues' do
      project = attributes_for(:project, autoclose_referenced_issues: false)

      post api(path, user), params: project

      expect(json_response['autoclose_referenced_issues']).to be_falsey
    end

    it 'sets the merge method of a project to rebase merge' do
      project = attributes_for(:project, merge_method: 'rebase_merge')

      post api(path, user), params: project

      expect(json_response['merge_method']).to eq('rebase_merge')
    end

    it 'rejects invalid values for merge_method' do
      project = attributes_for(:project, merge_method: 'totally_not_valid_method')

      post api(path, user), params: project

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'ignores import_url when it is nil' do
      project = attributes_for(:project, import_url: nil)

      post api(path, user), params: project

      expect(response).to have_gitlab_http_status(:created)
    end

    context 'with repository_object_format' do
      context 'when sha1' do
        it 'creates a project with SHA1 repository' do
          project = attributes_for(:project)

          post api(path, user), params: project.merge(repository_object_format: 'sha1')

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['repository_object_format']).to eq 'sha1'
        end
      end

      context 'when sha256' do
        it 'creates a project with SHA256 repository' do
          project = attributes_for(:project)

          post api(path, user), params: project.merge(repository_object_format: 'sha256')

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['repository_object_format']).to eq 'sha256'
        end

        context 'when "support_sha256_repositories" FF is disabled' do
          before do
            stub_feature_flags(support_sha256_repositories: false)
          end

          it 'creates a project with SHA1 repository' do
            project = attributes_for(:project)

            post api(path, user), params: project.merge(repository_object_format: 'sha256')

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['repository_object_format']).to eq 'sha1'
          end
        end
      end

      context 'when unknown format' do
        it 'rejects a project creation' do
          project = attributes_for(:project)

          post api(path, user), params: project.merge(repository_object_format: 'unknown')

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'when a visibility level is restricted' do
      let(:project_param) { attributes_for(:project, visibility: 'public') }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'does not allow a non-admin to use a restricted visibility level' do
        post api(path, user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['visibility_level'].first).to(
          match('restricted by your GitLab administrator')
        )
      end

      it 'allows an admin to override restricted visibility settings' do
        post api(path, admin), params: project_param

        expect(json_response['visibility']).to eq('public')
      end
    end
  end

  describe 'GET /users/:user_id/projects/' do
    let_it_be(:public_project) { create(:project, :public, creator_id: user4.id, namespace: user4.namespace) }

    it 'returns error when user not found' do
      get api("/users/#{non_existing_record_id}/projects/")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns projects filtered by user id' do
      get api("/users/#{user4.id}/projects/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :user_projects_api do
      def request
        get api("/users/#{user4.id}/projects/")
      end
    end

    it 'includes container_registry_access_level' do
      get api("/users/#{user4.id}/projects/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.first.keys).to include('container_registry_access_level')
    end

    context 'filter by updated_at' do
      it 'returns only projects updated on the given timeframe' do
        get api("/users/#{user.id}/projects", user),
          params: { updated_before: 2.days.ago.iso8601, updated_after: 6.days.ago }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |project| project['id'] }).to contain_exactly(project2.id, project.id)
      end
    end

    context 'and using id_after' do
      let_it_be(:another_public_project) { create(:project, :public, creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id_after filter given' do
        get api("/users/#{user4.id}/projects?id_after=#{public_project.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(another_public_project.id)
      end

      it 'returns both projects without a id_after filter' do
        get api("/users/#{user4.id}/projects", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id, another_public_project.id)
      end
    end

    context 'and using id_before' do
      let_it_be(:another_public_project) { create(:project, :public, creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id_before filter given' do
        get api("/users/#{user4.id}/projects?id_before=#{another_public_project.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
      end

      it 'returns both projects without a id_before filter' do
        get api("/users/#{user4.id}/projects", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id, another_public_project.id)
      end
    end

    context 'and using both id_before and id_after' do
      let_it_be(:more_projects) { create_list(:project, 5, :public, creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id matching the range' do
        get api("/users/#{user4.id}/projects?id_after=#{more_projects.first.id}&id_before=#{more_projects.last.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(*more_projects[1..-2].map(&:id))
      end
    end

    it 'returns projects filtered by username' do
      get api("/users/#{user4.username}/projects/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
    end

    it 'returns projects filtered by minimal access level' do
      private_project1 = create(:project, :private, name: 'private_project1', creator_id: user4.id, namespace: user4.namespace)
      private_project2 = create(:project, :private, name: 'private_project2', creator_id: user4.id, namespace: user4.namespace)
      private_project1.add_developer(user2)
      private_project2.add_reporter(user2)

      get api("/users/#{user4.id}/projects/", user2), params: { min_access_level: 30 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(private_project1.id)
    end

    context 'and using an admin to search', :enable_admin_mode do
      it 'returns users projects when authenticated as admin' do
        private_project1 = create(:project, :private, name: 'private_project1', creator_id: user4.id, namespace: user4.namespace)

        # min_access_level does not make any difference when admins search for a user's projects
        get api("/users/#{user4.id}/projects/", admin), params: { min_access_level: 30 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(project4.id, private_project1.id, public_project.id)
      end
    end

    context 'and using the programming language filter' do
      include_context 'with language detection'

      it 'filters case-insensitively by programming language' do
        get api('/projects', user), params: { with_programming_language: 'ruby' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id)
      end
    end
  end

  describe 'GET /users/:user_id/starred_projects/' do
    before do
      user3.update!(starred_projects: [project, project2, project3])
      user3.reload
    end

    let(:path) { "/users/#{user3.id}/starred_projects/" }

    it 'returns error when user not found' do
      get api("/users/#{non_existing_record_id}/starred_projects/")

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :user_starred_projects_api do
      def request
        get api(path)
      end
    end

    context 'with a public profile' do
      it 'returns projects filtered by user' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] })
          .to contain_exactly(project.id, project2.id, project3.id)
      end

      context 'filter by updated_at' do
        it 'returns only projects updated on the given timeframe' do
          get api(path, user),
            params: { updated_before: 2.days.ago.iso8601, updated_after: 6.days.ago }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.map { |project| project['id'] }).to contain_exactly(project2.id, project.id)
        end
      end
    end

    context 'with a private profile' do
      before do
        user3.update!(private_profile: true)
        user3.reload
      end

      context 'user does not have access to view the private profile' do
        it 'returns no projects' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response).to be_empty
        end
      end

      context 'user has access to view the private profile' do
        it 'returns projects filtered by user' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] })
            .to contain_exactly(project.id, project2.id, project3.id)
        end
      end
    end
  end

  describe 'GET /users/:user_id/contributed_projects/' do
    let(:path) { "/users/#{user3.id}/contributed_projects/" }

    let_it_be(:project1) { create(:project, :public, path: 'my-project') }
    let_it_be(:project2) { create(:project, :public) }
    let_it_be(:project3) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }

    before do
      private_project.add_maintainer(user3)

      create(:push_event, project: project1, author: user3)
      create(:push_event, project: project2, author: user3)
      create(:push_event, project: private_project, author: user3)
    end

    it 'returns error when user not found' do
      get api("/users/#{non_existing_record_id}/contributed_projects/", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :user_contributed_projects_api do
      def request
        get api(path)
      end
    end

    context 'with a public profile' do
      it 'returns projects filtered by user' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] })
          .to contain_exactly(project1.id, project2.id)
      end
    end

    context 'with a private profile' do
      before do
        user3.update!(private_profile: true)
        user3.reload
      end

      context 'user does not have access to view the private profile' do
        it 'returns no projects', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444704' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response).to be_empty
        end
      end

      context 'user has access to view the private profile as an admin' do
        it 'returns projects filtered by user' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] })
            .to contain_exactly(project1.id, project2.id, private_project.id)
        end
      end
    end
  end

  describe 'POST /projects/user/:id' do
    let(:path) { "/projects/user/#{user.id}" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { name: 'Foo Project' } }
    end

    it 'creates new project without path but with name and return 201' do
      expect { post api(path, admin, admin_mode: true), params: { name: 'Foo Project' } }.to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.find(json_response['id'])

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api(path, admin, admin_mode: true), params: { path: 'path-project-Foo', name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(:created)

      project = Project.find(json_response['id'])

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('path-project-Foo')
    end

    it_behaves_like 'create project with default branch parameter' do
      subject(:request) { post api(path, admin, admin_mode: true), params: params }
    end

    it 'responds with 400 on failure and not project' do
      expect { post api(path, admin, admin_mode: true) }
        .not_to change { Project.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'sets container_registry_enabled' do
      project = attributes_for(:project).tap do |attrs|
        attrs[:container_registry_enabled] = true
      end

      post api(path, admin, admin_mode: true), params: project

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['container_registry_enabled']).to eq(true)
      expect(Project.find_by(path: project[:path]).container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end

    it 'assigns attributes to project' do
      project = attributes_for(:project, {
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false,
        request_access_enabled: true,
        jobs_enabled: true
      })

      post api(path, admin, admin_mode: true), params: project

      expect(response).to have_gitlab_http_status(:created)

      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker has_external_wiki path storage_version namespace].include?(k)

        expect(json_response[k.to_s]).to eq(v)
      end

      # Check namespace
      created_project = Project.find_by_path(project[:path])
      expect(created_project.namespace.id).to eq(user.namespace.id)
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api(path, admin, admin_mode: true), params: project

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api(path, admin, admin_mode: true), params: project

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['visibility']).to eq('private')
    end

    it 'sets a project as not allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as not removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: false)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_falsey
    end

    it 'sets a project as removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: true)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if pipeline succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as not allowing merge when pipeline is skipped' do
      project = attributes_for(:project, allow_merge_on_skipped_pipeline: false)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['allow_merge_on_skipped_pipeline']).to be_falsey
    end

    it 'sets a project as allowing merge when pipeline is skipped' do
      project = attributes_for(:project, allow_merge_on_skipped_pipeline: true)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['allow_merge_on_skipped_pipeline']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api(path, admin, admin_mode: true), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end

    context 'container_registry_enabled' do
      using RSpec::Parameterized::TableSyntax

      where(:container_registry_enabled, :container_registry_access_level) do
        true  | ProjectFeature::ENABLED
        false | ProjectFeature::DISABLED
      end

      with_them do
        it 'setting container_registry_enabled also sets container_registry_access_level' do
          project_attributes = attributes_for(:project).tap do |attrs|
            attrs[:container_registry_enabled] = container_registry_enabled
          end

          post api(path, admin, admin_mode: true), params: project_attributes

          project = Project.find_by(path: project_attributes[:path])
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['container_registry_access_level']).to eq(ProjectFeature.str_from_access_level(container_registry_access_level))
          expect(json_response['container_registry_enabled']).to eq(container_registry_enabled)
          expect(project.container_registry_access_level).to eq(container_registry_access_level)
          expect(project.container_registry_enabled).to eq(container_registry_enabled)
        end
      end
    end

    context 'container_registry_access_level' do
      using RSpec::Parameterized::TableSyntax

      where(:container_registry_access_level, :container_registry_enabled) do
        'enabled'  | true
        'private'  | true
        'disabled' | false
      end

      with_them do
        it 'setting container_registry_access_level also sets container_registry_enabled' do
          project_attributes = attributes_for(:project).tap do |attrs|
            attrs[:container_registry_access_level] = container_registry_access_level
          end

          post api(path, admin, admin_mode: true), params: project_attributes

          project = Project.find_by(path: project_attributes[:path])
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['container_registry_access_level']).to eq(container_registry_access_level)
          expect(json_response['container_registry_enabled']).to eq(container_registry_enabled)
          expect(project.container_registry_access_level).to eq(ProjectFeature.access_level_from_str(container_registry_access_level))
          expect(project.container_registry_enabled).to eq(container_registry_enabled)
        end
      end
    end
  end

  describe "GET /projects/:id/groups" do
    let_it_be(:root_group) { create(:group, :public, name: 'root group') }
    let_it_be(:project_group) { create(:group, :public, parent: root_group, name: 'project group') }
    let_it_be(:shared_group_with_dev_access) { create(:group, :private, parent: root_group, name: 'shared group') }
    let_it_be(:shared_group_with_reporter_access) { create(:group, :public) }
    let_it_be(:private_project) { create(:project, :private, group: project_group) }
    let_it_be(:public_project) { create(:project, :public, group: project_group) }

    let(:path) { "/projects/#{private_project.id}/groups" }

    before_all do
      create(:project_group_link, :developer, group: shared_group_with_dev_access, project: private_project)
      create(:project_group_link, :reporter, group: shared_group_with_reporter_access, project: private_project)
    end

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    shared_examples_for 'successful groups response' do
      it 'returns an array of groups' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |g| g['name'] }).to match_array(expected_groups.map(&:name))
      end
    end

    context 'when unauthenticated' do
      it 'does not return groups for private projects' do
        get api(path)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'for public projects' do
        subject(:request) { get api("/projects/#{public_project.id}/groups") }

        it_behaves_like 'successful groups response' do
          let(:expected_groups) { [root_group, project_group] }
        end
      end
    end

    context 'when authenticated as user' do
      context 'when user does not have access to the project' do
        it 'does not return groups' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user has access to the project' do
        subject(:request) { get api(path, user), params: params }

        let(:params) { {} }

        before do
          private_project.add_developer(user)
        end

        it_behaves_like 'successful groups response' do
          let(:expected_groups) { [root_group, project_group] }
        end

        context 'when search by root group name' do
          let(:params) { { search: 'root' } }

          it_behaves_like 'successful groups response' do
            let(:expected_groups) { [root_group] }
          end
        end

        context 'with_shared option is on' do
          let(:params) { { with_shared: true } }

          it_behaves_like 'successful groups response' do
            let(:expected_groups) { [root_group, project_group, shared_group_with_dev_access, shared_group_with_reporter_access] }
          end

          context 'when shared_min_access_level is set' do
            let(:params) { super().merge(shared_min_access_level: Gitlab::Access::DEVELOPER) }

            it_behaves_like 'successful groups response' do
              let(:expected_groups) { [root_group, project_group, shared_group_with_dev_access] }
            end
          end

          context 'when shared_visible_only is on' do
            let(:params) { super().merge(shared_visible_only: true) }

            it_behaves_like 'successful groups response' do
              let(:expected_groups) { [root_group, project_group, shared_group_with_reporter_access] }
            end
          end

          context 'when search by shared group name' do
            let(:params) { super().merge(search: 'shared') }

            it_behaves_like 'successful groups response' do
              let(:expected_groups) { [shared_group_with_dev_access] }
            end
          end

          context 'when skip_groups is set' do
            let(:params) { super().merge(skip_groups: [shared_group_with_dev_access.id, root_group.id]) }

            it_behaves_like 'successful groups response' do
              let(:expected_groups) { [shared_group_with_reporter_access, project_group] }
            end
          end
        end
      end
    end

    context 'when authenticated as admin' do
      subject(:request) { get api(path, admin, admin_mode: true) }

      it_behaves_like 'successful groups response' do
        let(:expected_groups) { [root_group, project_group] }
      end
    end
  end

  describe 'GET /project/:id/share_locations' do
    let_it_be(:root_group) { create(:group, :public, name: 'root group', path: 'root-group-path') }
    let_it_be(:project_group1) { create(:group, :public, parent: root_group, name: 'group1', path: 'group-1-path') }
    let_it_be(:project_group2) { create(:group, :public, parent: root_group, name: 'group2', path: 'group-2-path') }
    let_it_be(:project) { create(:project, :private, group: project_group1) }
    let(:path) { "/projects/#{project.id}/share_locations" }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    shared_examples_for 'successful groups response' do
      it 'returns an array of groups' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |g| g['name'] }).to match_array(expected_groups.map(&:name))
      end
    end

    context 'when unauthenticated' do
      it 'does not return the groups for the given project' do
        get api(path)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated' do
      context 'when user is not the owner of the project' do
        it 'does not return the groups' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is the owner of the project' do
        subject(:request) { get api(path, user), params: params }

        let(:params) { {} }

        before do
          project.add_owner(user)
          project_group1.add_developer(user)
          project_group2.add_developer(user)
        end

        context 'with default search' do
          it_behaves_like 'successful groups response' do
            let(:expected_groups) { [project_group2] }
          end
        end

        context 'when searching by group name' do
          context 'searching by group name' do
            it_behaves_like 'successful groups response' do
              let(:params) { { search: 'group2' } }
              let(:expected_groups) { [project_group2] }
            end
          end

          context 'searching by full group path' do
            let_it_be(:project_group2_subgroup) do
              create(:group, :public, parent: project_group2, name: 'subgroup', path: 'subgroup-path')
            end

            it_behaves_like 'successful groups response' do
              let(:params) { { search: 'root-group-path/group-2-path/subgroup-path' } }
              let(:expected_groups) { [project_group2_subgroup] }
            end
          end
        end
      end
    end

    context 'when authenticated as admin' do
      subject(:request) { get api(path, admin, admin_mode: true), params: {} }

      context 'without share_with_group_lock' do
        it_behaves_like 'successful groups response' do
          let(:expected_groups) { [project_group2] }
        end
      end

      context 'with share_with_group_lock' do
        before do
          project.namespace.update!(share_with_group_lock: true)
        end

        it_behaves_like 'successful groups response' do
          let(:expected_groups) { [] }
        end
      end
    end
  end

  describe 'GET /projects/:id' do
    let(:path) { "/projects/#{project.id}" }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :project_api do
      def request
        get api(path)
      end
    end

    context 'when unauthenticated' do
      it 'does not return private projects' do
        private_project = create(:project, :private)

        get api("/projects/#{private_project.id}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns public projects' do
        public_project = create(:project, :repository, :public)

        get api("/projects/#{public_project.id}")

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(public_project.id)
        expect(json_response['description']).to eq(public_project.description)
        expect(json_response['default_branch']).to eq(public_project.default_branch)
        expect(json_response['ci_config_path']).to eq(public_project.ci_config_path)
        expect(json_response.keys).not_to include('permissions')
      end

      context 'the project is a public fork' do
        it 'shows details of a public fork parent' do
          public_project = create(:project, :repository, :public)
          fork = fork_project(public_project)

          get api("/projects/#{fork.id}")

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['forked_from_project']).to include('id' => public_project.id)
        end

        it 'hides details of a private fork parent' do
          public_project = create(:project, :repository, :public)
          parent_user = create(:user)
          public_project.team.add_developer(parent_user)

          fork = fork_project(public_project, user)

          # Make the parent private
          public_project.visibility = Gitlab::VisibilityLevel::PRIVATE
          public_project.save!

          get api("/projects/#{fork.id}")

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['forked_from_project']).to be_nil
        end
      end

      context 'and the project has a private repository' do
        let(:project) { create(:project, :repository, :public, :repository_private) }
        let(:protected_attributes) { %w[default_branch ci_config_path] }

        it 'hides protected attributes of private repositories if user is not a member' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          protected_attributes.each do |attribute|
            expect(json_response.keys).not_to include(attribute)
          end
        end

        it 'exposes protected attributes of private repositories if user is a member' do
          project.add_developer(user)

          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
          protected_attributes.each do |attribute|
            expect(json_response.keys).to include(attribute)
          end
        end
      end
    end

    context 'when authenticated as an admin', :with_license do
      before do
        stub_container_registry_config(enabled: true, host_port: 'registry.example.org:5000')
      end

      let(:project_attributes_file) { 'spec/requests/api/project_attributes.yml' }
      let(:project_attributes) { YAML.load_file(project_attributes_file) }

      let(:expected_keys) do
        keys = project_attributes.flat_map do |relation, relation_config|
          begin
            actual_keys = project.send(relation).attributes.keys
          rescue NoMethodError
            actual_keys = ["#{relation} is nil"]
          end
          unexposed_attributes = relation_config['unexposed_attributes'] || []
          remapped_attributes = relation_config['remapped_attributes'] || {}
          computed_attributes = relation_config['computed_attributes'] || []
          actual_keys - unexposed_attributes - remapped_attributes.keys + remapped_attributes.values + computed_attributes
        end

        unless Gitlab.ee?
          keys -= %w[
            approvals_before_merge
            compliance_frameworks
            mirror
            requirements_access_level
            requirements_enabled
            security_and_compliance_enabled
            issues_template
            merge_requests_template
            secret_push_protection_enabled
          ]
        end

        keys
      end

      it 'returns a project by id' do
        project
        project_member
        group = create(:group)
        link = create(:project_group_link, project: project, group: group)

        get api(path, admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['description_html']).to eq(project.description_html)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['tag_list']).to be_an Array # deprecated in favor of 'topics'
        expect(json_response['topics']).to be_an Array
        expect(json_response['archived']).to be_falsey
        expect(json_response['visibility']).to be_present
        expect(json_response['ssh_url_to_repo']).to be_present
        expect(json_response['http_url_to_repo']).to be_present
        expect(json_response['web_url']).to be_present
        expect(json_response['container_registry_image_prefix']).to eq("registry.example.org:5000/#{project.full_path}")
        expect(json_response['owner']).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to be_present
        expect(json_response['issues_enabled']).to be_present
        expect(json_response['merge_requests_enabled']).to be_present
        expect(json_response['can_create_merge_request_in']).to be_present
        expect(json_response['wiki_enabled']).to be_present
        expect(json_response['jobs_enabled']).to be_present
        expect(json_response['snippets_enabled']).to be_present
        expect(json_response['container_registry_enabled']).to be_present
        expect(json_response['container_registry_access_level']).to be_present
        expect(json_response['created_at']).to be_present
        expect(json_response['updated_at']).to be_present
        expect(json_response['last_activity_at']).to be_present
        expect(json_response['shared_runners_enabled']).to be_present
        expect(json_response['group_runners_enabled']).to be_present
        expect(json_response['creator_id']).to be_present
        expect(json_response['namespace']).to be_present
        expect(json_response['avatar_url']).to be_nil
        expect(json_response['star_count']).to be_present
        expect(json_response['forks_count']).to be_present
        expect(json_response['public_jobs']).to be_present
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['only_allow_merge_if_pipeline_succeeds']).to eq(project.only_allow_merge_if_pipeline_succeeds)
        expect(json_response['allow_merge_on_skipped_pipeline']).to eq(project.allow_merge_on_skipped_pipeline)
        expect(json_response['restrict_user_defined_variables']).to eq(project.restrict_user_defined_variables?)
        expect(json_response['ci_pipeline_variables_minimum_override_role']).to eq(project.ci_pipeline_variables_minimum_override_role.to_s)
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
        expect(json_response['security_and_compliance_access_level']).to be_present
        expect(json_response['releases_access_level']).to be_present
        expect(json_response['environments_access_level']).to be_present
        expect(json_response['feature_flags_access_level']).to be_present
        expect(json_response['infrastructure_access_level']).to be_present
        expect(json_response['monitor_access_level']).to be_present
        expect(json_response['warn_about_potentially_unwanted_characters']).to be_present
        expect(json_response).to have_key('emails_disabled')
        expect(json_response).to have_key('emails_enabled')
      end

      it 'exposes all necessary attributes' do
        create(:project_group_link, project: project)

        get api(path, admin, admin_mode: true)

        diff = Set.new(json_response.keys) ^ Set.new(expected_keys)

        expect(diff).to be_empty, failure_message(diff)
      end

      def failure_message(diff)
        <<~MSG
          It looks like project's set of exposed attributes is different from the expected set.

          The following attributes are missing or newly added:
          #{diff.to_a.to_sentence}

          Please update #{project_attributes_file} file"
        MSG
      end
    end

    context 'when authenticated as a regular user' do
      before do
        project
        project_member
        stub_container_registry_config(enabled: true, host_port: 'registry.example.org:5000')
      end

      it 'returns a project by id' do
        group = create(:group)
        link = create(:project_group_link, project: project, group: group)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['tag_list']).to be_an Array # deprecated in favor of 'topics'
        expect(json_response['topics']).to be_an Array
        expect(json_response['archived']).to be_falsey
        expect(json_response['visibility']).to be_present
        expect(json_response['ssh_url_to_repo']).to be_present
        expect(json_response['http_url_to_repo']).to be_present
        expect(json_response['web_url']).to be_present
        expect(json_response['container_registry_image_prefix']).to eq("registry.example.org:5000/#{project.full_path}")
        expect(json_response['owner']).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to be_present
        expect(json_response['issues_enabled']).to be_present
        expect(json_response['merge_requests_enabled']).to be_present
        expect(json_response['can_create_merge_request_in']).to be_present
        expect(json_response['wiki_enabled']).to be_present
        expect(json_response['jobs_enabled']).to be_present
        expect(json_response['snippets_enabled']).to be_present
        expect(json_response['snippets_access_level']).to be_present
        expect(json_response['pages_access_level']).to be_present
        expect(json_response['repository_access_level']).to be_present
        expect(json_response['issues_access_level']).to be_present
        expect(json_response['merge_requests_access_level']).to be_present
        expect(json_response['forking_access_level']).to be_present
        expect(json_response['analytics_access_level']).to be_present
        expect(json_response['wiki_access_level']).to be_present
        expect(json_response['builds_access_level']).to be_present
        expect(json_response['security_and_compliance_access_level']).to be_present
        expect(json_response['releases_access_level']).to be_present
        expect(json_response['environments_access_level']).to be_present
        expect(json_response['feature_flags_access_level']).to be_present
        expect(json_response['infrastructure_access_level']).to be_present
        expect(json_response['monitor_access_level']).to be_present
        expect(json_response['resolve_outdated_diff_discussions']).to eq(project.resolve_outdated_diff_discussions)
        expect(json_response['remove_source_branch_after_merge']).to be_truthy
        expect(json_response['container_registry_enabled']).to be_present
        expect(json_response['container_registry_access_level']).to be_present
        expect(json_response['created_at']).to be_present
        expect(json_response['last_activity_at']).to be_present
        expect(json_response['shared_runners_enabled']).to be_present
        expect(json_response['group_runners_enabled']).to be_present
        expect(json_response['creator_id']).to be_present
        expect(json_response['namespace']).to be_present
        expect(json_response['import_status']).to be_present
        expect(json_response).to include("import_error")
        expect(json_response).to have_key('avatar_url')
        expect(json_response['star_count']).to be_present
        expect(json_response['forks_count']).to be_present
        expect(json_response['public_jobs']).to be_present
        expect(json_response).to have_key('ci_config_path')
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['shared_with_groups'][0]).to have_key('expires_at')
        expect(json_response['only_allow_merge_if_pipeline_succeeds']).to eq(project.only_allow_merge_if_pipeline_succeeds)
        expect(json_response['allow_merge_on_skipped_pipeline']).to eq(project.allow_merge_on_skipped_pipeline)
        expect(json_response['restrict_user_defined_variables']).to eq(project.restrict_user_defined_variables?)
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
        expect(json_response['ci_default_git_depth']).to eq(project.ci_default_git_depth)
        expect(json_response['ci_forward_deployment_enabled']).to eq(project.ci_forward_deployment_enabled)
        expect(json_response['ci_forward_deployment_rollback_allowed']).to eq(project.ci_forward_deployment_rollback_allowed)
        expect(json_response['ci_allow_fork_pipelines_to_run_in_parent_project']).to eq(project.ci_allow_fork_pipelines_to_run_in_parent_project)
        expect(json_response['ci_separated_caches']).to eq(project.ci_separated_caches)
        expect(json_response['merge_method']).to eq(project.merge_method.to_s)
        expect(json_response['squash_option']).to eq(project.squash_option.to_s)
        expect(json_response['readme_url']).to eq(project.readme_url)
        expect(json_response).to have_key 'packages_enabled'
        expect(json_response['keep_latest_artifact']).to be_present
        expect(json_response['warn_about_potentially_unwanted_characters']).to be_present
      end

      it 'returns a group link with expiration date' do
        group = create(:group)
        expires_at = 5.days.from_now.to_date
        link = create(:project_group_link, project: project, group: group, expires_at: expires_at)

        get api(path, user)

        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['shared_with_groups'][0]['expires_at']).to eq(expires_at.to_s)
      end

      context 'when path name is specified' do
        it 'returns a project' do
          get api("/projects/#{CGI.escape(project.full_path)}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq(project.name)
        end

        it 'returns a project using case-insensitive search' do
          get api("/projects/#{CGI.escape(project.full_path.swapcase)}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq(project.name)
        end
      end

      context 'when a project is moved' do
        let(:redirect_route) { 'new/project/location' }
        let(:perform_request) { get api("/projects/#{CGI.escape(redirect_route)}", user), params: { license: true } }

        before do
          project.route.create_redirect(redirect_route)
        end

        it 'redirects to the new project location' do
          perform_request

          expect(response).to have_gitlab_http_status(:moved_permanently)

          url = response.headers['Location']
          expect(url).to start_with("#{request.base_url}/api/v4/projects/#{project.id}")
          expect(CGI.parse(URI(url).query)).to include({ 'license' => ['true'] })
        end

        context 'when a user do not have access' do
          let(:user) { create(:user) }

          it 'returns a 404 error' do
            perform_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      it 'returns a 404 error if not found' do
        get api("/projects/#{non_existing_record_id}", user)
        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)
        get api(path, other_user)
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'handles users with dots' do
        dot_user = create(:user, username: 'dot.user')
        project = create(:project, creator_id: dot_user.id, namespace: dot_user.namespace)

        get api("/projects/#{CGI.escape(project.full_path)}", dot_user)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(project.name)
      end

      it 'exposes namespace fields' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['namespace']).to eq({
          'id' => user.namespace.id,
          'name' => user.namespace.name,
          'path' => user.namespace.path,
          'kind' => user.namespace.kind,
          'full_path' => user.namespace.full_path,
          'parent_id' => nil,
          'avatar_url' => user.avatar_url,
          'web_url' => Gitlab::Routing.url_helpers.user_url(user)
        })
      end

      it "does not include license fields by default" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include('license', 'license_url')
      end

      it 'includes license fields when requested' do
        get api(path, user), params: { license: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['license']).to eq({
          'key' => project.repository.license.key,
          'name' => project.repository.license.name,
          'nickname' => project.repository.license.nickname,
          'html_url' => project.repository.license.url,
          'source_url' => nil
        })
      end

      it "does not include statistics by default" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include 'statistics'
      end

      it "includes statistics if requested" do
        get api(path, user), params: { statistics: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include 'statistics'
      end

      context "and the project has a private repository" do
        let(:project) { create(:project, :public, :repository, :repository_private) }

        it "does not include statistics if user is not a member" do
          get api(path, user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).not_to include 'statistics'
        end

        it "includes statistics if user is a member" do
          project.add_developer(user)

          get api(path, user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include 'statistics'
        end

        it "includes statistics also when repository is disabled" do
          project.add_developer(user)
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

          get api(path, user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include 'statistics'
        end
      end

      it "includes import_error if user can admin project" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include("import_error")
      end

      it "does not include import_error if user cannot admin project" do
        get api(path, user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include("import_error")
      end

      it 'returns 404 when project is marked for deletion' do
        project.update!(pending_delete: true)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      context 'links exposure' do
        it 'exposes related resources full URIs' do
          get api(path, user)

          links = json_response['_links']

          expect(links['self']).to end_with("/api/v4/projects/#{project.id}")
          expect(links['issues']).to end_with("/api/v4/projects/#{project.id}/issues")
          expect(links['merge_requests']).to end_with("/api/v4/projects/#{project.id}/merge_requests")
          expect(links['repo_branches']).to end_with("/api/v4/projects/#{project.id}/repository/branches")
          expect(links['labels']).to end_with("/api/v4/projects/#{project.id}/labels")
          expect(links['events']).to end_with("/api/v4/projects/#{project.id}/events")
          expect(links['members']).to end_with("/api/v4/projects/#{project.id}/members")
          expect(links['cluster_agents']).to end_with("/api/v4/projects/#{project.id}/cluster_agents")
        end

        it 'filters related URIs when their feature is not enabled' do
          project = create(
            :project,
            :public,
            :merge_requests_disabled,
            :issues_disabled,
            creator_id: user.id,
            namespace: user.namespace
          )

          get api("/projects/#{project.id}", user)

          links = json_response['_links']

          expect(links.has_key?('merge_requests')).to be_falsy
          expect(links.has_key?('issues')).to be_falsy
          expect(links['self']).to end_with("/api/v4/projects/#{project.id}")
        end
      end

      context 'the project is a fork' do
        it 'shows details of a visible fork parent' do
          fork = fork_project(project, user)

          get api("/projects/#{fork.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['forked_from_project']).to include('id' => project.id)
        end

        it 'hides details of a hidden fork parent' do
          fork = fork_project(project, user)
          fork_user = create(:user)
          fork.team.add_developer(fork_user)

          get api("/projects/#{fork.id}", fork_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['forked_from_project']).to be_nil
        end
      end

      describe 'permissions' do
        context 'all projects' do
          before do
            project.add_maintainer(user)
          end

          it 'contains permission information' do
            get api("/projects", user)

            expect(response).to have_gitlab_http_status(:ok)
            detail_of_project = json_response.find { |detail| detail['id'] == project.id }

            expect(detail_of_project.dig('permissions', 'project_access', 'access_level'))
            .to eq(Gitlab::Access::MAINTAINER)
            expect(detail_of_project.dig('permissions', 'group_access')).to be_nil
          end
        end

        context 'personal project' do
          it 'sets project access and returns 200' do
            project.add_maintainer(user)
            get api(path, user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['permissions']['project_access']['access_level'])
            .to eq(Gitlab::Access::MAINTAINER)
            expect(json_response['permissions']['group_access']).to be_nil
          end
        end

        context 'group project' do
          let(:project2) { create(:project, group: create(:group)) }

          before do
            project2.group.add_owner(user)
          end

          it 'sets the owner and return 200' do
            get api("/projects/#{project2.id}", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['permissions']['project_access']).to be_nil
            expect(json_response['permissions']['group_access']['access_level'])
            .to eq(Gitlab::Access::OWNER)
          end
        end

        context 'nested group project' do
          let(:group) { create(:group) }
          let(:nested_group) { create(:group, parent: group) }
          let(:project2) { create(:project, group: nested_group) }

          before do
            project2.group.parent.add_owner(user)
          end

          it 'sets group access and return 200' do
            get api("/projects/#{project2.id}", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['permissions']['project_access']).to be_nil
            expect(json_response['permissions']['group_access']['access_level'])
            .to eq(Gitlab::Access::OWNER)
          end

          context 'with various access levels across nested groups' do
            before do
              project2.group.add_maintainer(user)
            end

            it 'sets the maximum group access and return 200' do
              get api("/projects/#{project2.id}", user)

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['permissions']['project_access']).to be_nil
              expect(json_response['permissions']['group_access']['access_level'])
              .to eq(Gitlab::Access::OWNER)
            end
          end
        end
      end

      context 'when project belongs to a group namespace' do
        let(:group) { create(:group, :with_avatar) }
        let(:project) { create(:project, namespace: group) }
        let!(:project_member) { create(:project_member, :developer, user: user, project: project) }

        it 'returns group web_url and avatar_url' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)

          group_data = json_response['namespace']
          expect(group_data['web_url']).to eq(group.web_url)
          expect(group_data['avatar_url']).to eq(group.avatar_url)
        end
      end

      context 'when project belongs to a user namespace' do
        let_it_be(:user) { create(:user) }
        let_it_be(:project) { create(:project, namespace: user.namespace) }

        it 'returns user web_url and avatar_url' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)

          user_data = json_response['namespace']
          expect(user_data['web_url']).to eq("http://localhost/#{user.username}")
          expect(user_data['avatar_url']).to eq(user.avatar_url)
        end
      end
    end

    context 'when authenticated as a developer' do
      before do
        project
        project_member
      end

      it 'hides sensitive admin attributes' do
        get api(path, user3)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['ci_config_path']).to eq(project.ci_config_path)
        expect(json_response['forked_from_project']).to eq(project.forked_from_project)
        expect(json_response['service_desk_address']).to eq(::ServiceDesk::Emails.new(project).address)
        expect(json_response).not_to include(
          'ci_default_git_depth',
          'ci_forward_deployment_enabled',
          'ci_forward_deployment_rollback_allowed',
          'ci_job_token_scope_enabled',
          'ci_separated_caches',
          'ci_allow_fork_pipelines_to_run_in_parent_project',
          'build_git_strategy',
          'keep_latest_artifact',
          'restrict_user_defined_variables',
          'ci_pipeline_variables_minimum_override_role',
          'runners_token',
          'runner_token_expiration_interval',
          'group_runners_enabled',
          'auto_cancel_pending_pipelines',
          'build_timeout',
          'auto_devops_enabled',
          'auto_devops_deploy_strategy',
          'import_error',
          'ci_push_repository_for_job_token_allowed'
        )
      end
    end

    it_behaves_like 'storing arguments in the application context for the API' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, :public) }
      let(:expected_params) { { user: user.username, project: project.full_path } }

      subject { get api(path, user) }
    end

    describe 'repository_storage attribute' do
      let_it_be(:admin_mode) { false }

      before do
        get api(path, user, admin_mode: admin_mode)
      end

      context 'when authenticated as an admin' do
        let(:user) { create(:admin) }
        let_it_be(:admin_mode) { true }

        it 'returns repository_storage attribute' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['repository_storage']).to eq(project.repository_storage)
        end
      end

      context 'when authenticated as a regular user' do
        it 'does not return repository_storage attribute' do
          expect(json_response).not_to have_key('repository_storage')
        end
      end
    end

    it 'exposes service desk attributes' do
      get api(path, user)

      expect(json_response).to have_key 'service_desk_enabled'
      expect(json_response).to have_key 'service_desk_address'
    end

    context 'when project is shared to multiple groups' do
      it 'avoids N+1 queries', :use_sql_query_cache do
        create(:project_group_link, project: project)
        get api(path, user)
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new do
          get api(path, user)
        end

        create(:project_group_link, project: project)

        expect do
          get api(path, user)
        end.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'GET /projects/:id/users' do
    let(:path) { "/projects/#{project.id}/users" }

    shared_examples_for 'project users response' do
      let(:reporter_1) { create(:user) }
      let(:reporter_2) { create(:user) }

      before do
        project.add_reporter(reporter_1)
        project.add_reporter(reporter_2)
      end

      it 'returns the project users' do
        get api(path, current_user)

        user = project.namespace.first_owner

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(3)

        first_user = json_response.first
        expect(first_user['username']).to eq(user.username)
        expect(first_user['name']).to eq(user.name)
        expect(first_user.keys).to include(*%w[name username id state avatar_url web_url])

        ids = json_response.map { |raw_user| raw_user['id'] }
        expect(ids).to eq([user.id, reporter_1.id, reporter_2.id])
      end
    end

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    context 'when unauthenticated' do
      it_behaves_like 'project users response' do
        let(:project) { create(:project, :public) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated' do
      context 'valid request' do
        it_behaves_like 'project users response' do
          let(:project) { project4 }
          let(:current_user) { user4 }
        end
      end

      it 'returns a 404 error if not found' do
        get api("/projects/#{non_existing_record_id}/users", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)

        get api(path, other_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'filters out users listed in skip_users' do
        other_user = create(:user)
        project.team.add_developer(other_user)

        get api("/projects/#{project.id}/users?skip_users=#{user.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(2)
        expect(json_response.map { |m| m['id'] }).not_to include(user.id)
      end
    end
  end

  describe 'fork management' do
    let_it_be_with_refind(:project_fork_target) { create(:project) }
    let_it_be_with_refind(:project_fork_source) { create(:project, :public) }
    let_it_be_with_refind(:private_project_fork_source) { create(:project, :private) }

    describe 'POST /projects/:id/fork/:forked_from_id' do
      let(:path) { "/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { {} }
        let(:failed_status_code) { :not_found }
      end

      it 'refreshes the forks count cache' do
        expect(project_fork_source.forks_count).to be_zero
      end

      context 'user is a developer' do
        before do
          project_fork_target.add_developer(user)
        end

        it 'denies project to be forked from an existing project' do
          post api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'user is maintainer' do
        before do
          project_fork_target.add_maintainer(user)
        end

        it 'denies project to be forked from an existing project' do
          post api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'user is owner' do
        before do
          project_fork_target.add_owner(user)
        end

        context 'and user is a reporter of target group' do
          let_it_be_with_reload(:target_group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS) }
          let_it_be_with_reload(:project_fork_target) { create(:project, namespace: target_group) }

          before do
            target_group.add_reporter(user)
          end

          it 'fails as target namespace is unauthorized' do
            post api(path, user)

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['message']).to eq "401 Unauthorized - Target Namespace"
          end
        end

        context 'and user is a developer of target group' do
          let_it_be_with_reload(:target_group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS) }
          let_it_be_with_reload(:project_fork_target) { create(:project, namespace: target_group) }

          before do
            target_group.add_developer(user)
          end

          it 'allows project to be forked from an existing project' do
            expect(project_fork_target).not_to be_forked

            post api(path, user)
            project_fork_target.reload

            expect(response).to have_gitlab_http_status(:created)
            expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
            expect(project_fork_target.fork_network_member).to be_present
            expect(project_fork_target).to be_forked
          end
        end

        it 'fails without permission from forked_from project' do
          project_fork_source.project_feature.update_attribute(:forking_access_level, ProjectFeature::PRIVATE)

          post api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(project_fork_target.forked_from_project).to be_nil
          expect(project_fork_target.fork_network_member).not_to be_present
          expect(project_fork_target).not_to be_forked
        end

        it 'denies project to be forked from a private project' do
          post api("/projects/#{project_fork_target.id}/fork/#{private_project_fork_source.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'user is admin' do
        it 'allows project to be forked from an existing project' do
          expect(project_fork_target).not_to be_forked

          post api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'allows project to be forked from a private project' do
          post api("/projects/#{project_fork_target.id}/fork/#{private_project_fork_source.id}", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'refreshes the forks count cachce' do
          expect do
            post api(path, admin, admin_mode: true)
          end.to change(project_fork_source, :forks_count).by(1)
        end

        it 'fails if forked_from project which does not exist' do
          post api("/projects/#{project_fork_target.id}/fork/#{non_existing_record_id}", admin, admin_mode: true)
          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'fails with 409 if already forked' do
          other_project_fork_source = create(:project, :public)

          Projects::ForkService.new(project_fork_source, admin).execute(project_fork_target)

          post api("/projects/#{project_fork_target.id}/fork/#{other_project_fork_source.id}", admin, admin_mode: true)
          project_fork_target.reload

          expect(response).to have_gitlab_http_status(:conflict)
          expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
          expect(project_fork_target).to be_forked
        end

        context 'when forking process fails' do
          before do
            allow_next_instance_of(Projects::ForkService) do |instance|
              allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Error'))
            end
          end

          it 'fails with 400 error' do
            expect(project_fork_target).not_to be_forked

            post api(path, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq "Error"
            expect(project_fork_target).not_to be_forked
          end
        end

        context 'when fork target and source are the same' do
          it 'returns an error' do
            post api("/projects/#{project_fork_target.id}/fork/#{project_fork_target.id}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq 'Target project cannot be equal to source project'
          end
        end

        context 'when fork target and source project organization are not the same' do
          let_it_be(:organization) { create(:organization) }
          let_it_be(:project_fork_target_different_organization) { create(:project, organization: organization) }

          it 'returns an error' do
            post api("/projects/#{project_fork_target_different_organization.id}/fork/#{project_fork_source.id}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq 'Target project must belong to source project organization'
          end
        end
      end
    end

    describe 'DELETE /projects/:id/fork' do
      let(:path) { "/projects/#{project_fork_target.id}/fork" }

      it "is not visible to users outside group" do
        delete api(path, user)
        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when users belong to project group' do
        let(:project_fork_target) { create(:project, group: create(:group)) }

        before do
          project_fork_target.group.add_owner user
          project_fork_target.group.add_developer user2
        end

        context 'for a forked project' do
          before do
            post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin, admin_mode: true)
            project_fork_target.reload
            expect(project_fork_target.forked_from_project).to be_present
            expect(project_fork_target).to be_forked
          end

          it_behaves_like 'DELETE request permissions for admin mode' do
            let(:success_status_code) { :no_content }
            let(:failed_status_code) { :not_found }
          end

          it 'makes forked project unforked' do
            delete api(path, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:no_content)
            project_fork_target.reload
            expect(project_fork_target.forked_from_project).to be_nil
            expect(project_fork_target).not_to be_forked
          end

          it_behaves_like '412 response' do
            subject(:request) { api(path, admin, admin_mode: true) }
          end
        end

        it 'is forbidden to non-owner users' do
          delete api(path, user2)
          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'is idempotent if not forked' do
          expect(project_fork_target.forked_from_project).to be_nil
          delete api(path, admin, admin_mode: true)
          expect(response).to have_gitlab_http_status(:not_modified)
          expect(project_fork_target.reload.forked_from_project).to be_nil
        end
      end
    end

    describe 'GET /projects/:id/forks' do
      let_it_be_with_refind(:private_fork) { create(:project, :private, :empty_repo) }
      let_it_be(:member) { create(:user) }
      let_it_be(:non_member) { create(:user) }

      before_all do
        private_fork.add_developer(member)
      end

      context 'for a forked project' do
        before do
          post api("/projects/#{private_fork.id}/fork/#{project_fork_source.id}", admin, admin_mode: true)
          private_fork.reload
          expect(private_fork.forked_from_project).to be_present
          expect(private_fork).to be_forked
          project_fork_source.reload
          expect(project_fork_source.forks.length).to eq(1)
          expect(project_fork_source.forks).to include(private_fork)
        end

        context 'for a user that can access the forks' do
          it 'returns the forks' do
            get api("/projects/#{project_fork_source.id}/forks", member)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(1)
            expect(json_response[0]['name']).to eq(private_fork.name)
          end

          context 'filter by updated_at' do
            before do
              private_fork.update!(updated_at: 4.days.ago)
            end

            it 'returns only forks updated on the given timeframe' do
              get api("/projects/#{project_fork_source.id}/forks", member),
                params: { updated_before: 2.days.ago.iso8601, updated_after: 6.days.ago }

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response.map { |project| project['id'] }).to contain_exactly(private_fork.id)
            end
          end
        end

        context 'for a user that cannot access the forks' do
          it 'returns an empty array' do
            get api("/projects/#{project_fork_source.id}/forks", non_member)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(0)
          end
        end
      end

      context 'for a non-forked project' do
        it 'returns an empty array' do
          get api("/projects/#{project_fork_source.id}/forks")

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(0)
        end
      end
    end
  end

  describe "POST /projects/:id/share" do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:group_user) { create(:user) }
    let(:path) { "/projects/#{project.id}/share" }

    before do
      group.add_developer(user)
      group.add_developer(group_user)
    end

    it "shares project with group" do
      expires_at = 10.days.from_now.to_date

      expect do
        post api(path, user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at }
      end.to change { ProjectGroupLink.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['group_id']).to eq(group.id)
      expect(json_response['group_access']).to eq(Gitlab::Access::DEVELOPER)
      expect(json_response['expires_at']).to eq(expires_at.to_s)
    end

    it 'updates project authorization', :sidekiq_inline do
      expect do
        post api(path, user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER }
      end.to(
        change { group_user.can?(:read_project, project) }.from(false).to(true)
      )
    end

    it "returns a 400 error when group id is not given" do
      post api(path, user), params: { group_access: Gitlab::Access::DEVELOPER }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 400 error when access level is not given" do
      post api(path, user), params: { group_id: group.id }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 400 error when sharing is disabled" do
      project.namespace.update!(share_with_group_lock: true)
      post api(path, user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 404 error when user cannot read group' do
      private_group = create(:group, :private)

      post api(path, user), params: { group_id: private_group.id, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error when group does not exist' do
      post api(path, user), params: { group_id: non_existing_record_id, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 400 error when wrong params passed" do
      post api(path, user), params: { group_id: group.id, group_access: non_existing_record_access_level }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq 'group_access does not have a valid value'
    end

    it 'returns a 403 when a maintainer tries to create a link with OWNER access' do
      user = create(:user)
      project.add_maintainer(user)

      expect do
        post api(path, user), params: { group_id: group.id, group_access: Gitlab::Access::OWNER }
      end.to not_change { project.reload.project_group_links.count }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it "returns a 409 error when link is not saved" do
      allow(::Projects::GroupLinks::CreateService).to receive_message_chain(:new, :execute)
        .and_return({ status: :error, http_status: 409, message: 'error' })

      post api(path, user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(:conflict)
    end

    context 'when project is forked' do
      let(:forked_project) { fork_project(project) }
      let(:path) { "/projects/#{forked_project.id}/share" }

      it 'returns a 404 error when group does not exist' do
        forked_project.add_maintainer(user)
        post api(path, user), params: { group_id: non_existing_record_id, group_access: Gitlab::Access::DEVELOPER }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/invited_groups' do
    let_it_be(:main_group) { create(:group, :private, owners: user1) }
    let_it_be(:direct_group1) { create(:group, :private, owners: user1) }
    let_it_be(:direct_group2) { create(:group, :private, owners: user1) }
    let_it_be(:inherited_group) { create(:group, :private, owners: user1) }
    let_it_be(:main_project) { create(:project, group: main_group, owners: user1) }

    let(:path) { "/projects/#{main_project.id}/invited_groups" }

    before do
      create(:group_group_link, shared_group: main_group, shared_with_group: inherited_group)
      create(:project_group_link, group: direct_group1, project: main_project)
      create(:project_group_link, group: direct_group2, project: main_project)
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :project_invited_groups_api do
      def request
        get api(path)
      end
    end

    context 'when authenticated as user' do
      it 'returns the invited groups in the project', :aggregate_failures do
        get api(path, user1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(3)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(direct_group1.id, direct_group2.id, inherited_group.id)
      end
    end

    context 'when authenticated and user does not have the access' do
      it 'does not return the invited groups in the project', :aggregate_failures do
        get api(path, user2)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated as user' do
      let_it_be(:main_group) { create(:group, :public, owners: user2) }
      let_it_be(:direct_group_1) { create(:group, :public, owners: user2) }
      let_it_be(:direct_group_2) { create(:group, :private, owners: user2) }
      let_it_be(:new_project) { create(:project, :public, group: main_group, owners: user2) }

      let(:path) { "/projects/#{new_project.id}/invited_groups" }

      before do
        create(:project_group_link, group: direct_group_1, project: new_project)
        create(:project_group_link, group: direct_group_2, project: new_project)
      end

      it 'only returns the invited public groups in the project', :aggregate_failures do
        get api(path)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.length).to eq(1)
        group_ids = json_response.map { |group| group['id'] }
        expect(group_ids).to contain_exactly(direct_group_1.id)
      end
    end

    context "when search is present in request" do
      let_it_be(:direct_group_1) { create(:group, :public, name: "new direct", owners: user1) }
      let_it_be(:direct_group_2) { create(:group, :private, name: "other direct", owners: user1) }
      let_it_be(:new_project) { create(:project, :public, owners: user1) }

      let(:path) { "/projects/#{new_project.id}/invited_groups" }

      before do
        create(:project_group_link, group: direct_group_1, project: new_project)
        create(:project_group_link, group: direct_group_2, project: new_project)
      end

      it 'filters the invited groups in the group based on search params', :aggregate_failures do
        get api(path, user1), params: { search: 'new' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(direct_group_1.id)
      end
    end

    context 'when using min_access_level in the request' do
      let_it_be(:new_direct_group) { create(:group, :public, name: "new direct") }
      let_it_be(:other_direct_group) { create(:group, :private, name: "other direct") }
      let_it_be(:new_project) { create(:project, :public) }

      let(:path) { "/projects/#{new_project.id}/invited_groups" }

      before do
        new_direct_group.add_developer(user1)
        other_direct_group.add_owner(user1)
        create(:project_group_link, group: new_direct_group, project: new_project)
        create(:project_group_link, group: other_direct_group, project: new_project)
      end

      context 'with min_access_level parameter' do
        it 'returns an array of groups the user has at least owner access', :aggregate_failures do
          get api(path, user1), params: { min_access_level: Gitlab::Access::OWNER }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |group| group['id'] }).to contain_exactly(other_direct_group.id)
        end
      end
    end

    context "when include_relation is present in request" do
      let_it_be(:relation_main_group) { create(:group, :private, owners: user1) }
      let_it_be(:direct_group) { create(:group, owners: user1) }
      let_it_be(:inherited_group) { create(:group, owners: user1) }
      let_it_be(:new_relation_project) { create(:project, group: relation_main_group) }

      let(:path) { "/projects/#{new_relation_project.id}/invited_groups" }

      before do
        create(:project_group_link, group: direct_group, project: new_relation_project)
        create(:group_group_link, shared_group: relation_main_group, shared_with_group: inherited_group)
      end

      it 'filters the invited groups in the project based on direct relation params', :aggregate_failures do
        get api(path, user1), params: { relation: ['direct'] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.map { |group| group['id'] }).to contain_exactly(direct_group.id)
      end

      it 'filters the invited groups in the project based on inherited relation params', :aggregate_failures do
        get api(path, user1), params: { relation: ['inherited'] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.map { |group| group['id'] }).to contain_exactly(inherited_group.id)
      end

      it 'returns error message when include relation is invalid' do
        get api(path, user1), params: { relation: ['some random'] }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq("relation does not have a valid value")
      end
    end
  end

  describe 'DELETE /projects/:id/share/:group_id' do
    context 'for a valid group' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:group_user) { create(:user) }
      let(:group_access) { Gitlab::Access::DEVELOPER }

      before do
        group.add_developer(group_user)

        create(:project_group_link, group: group, project: project, group_access: group_access)
      end

      it 'returns 204 when deleting a group share' do
        delete api("/projects/#{project.id}/share/#{group.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(project.project_group_links).to be_empty
      end

      it 'updates project authorization', :sidekiq_inline do
        expect do
          delete api("/projects/#{project.id}/share/#{group.id}", user)
        end.to(
          change { group_user.can?(:read_project, project) }.from(true).to(false)
        )
      end

      it_behaves_like '412 response' do
        subject(:request) { api("/projects/#{project.id}/share/#{group.id}", user) }
      end

      it "returns an error when link is not destroyed" do
        allow(::Projects::GroupLinks::DestroyService).to receive_message_chain(:new, :execute)
          .and_return(ServiceResponse.error(message: '404 Not Found', reason: :not_found))

        delete api("/projects/#{project.id}/share/#{group.id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Not Found'
      end

      context 'when a MAINTAINER tries to destroy a link with OWNER access' do
        let(:group_access) { Gitlab::Access::OWNER }

        it 'returns 403' do
          user = create(:user)
          project.add_maintainer(user)

          expect do
            delete api("/projects/#{project.id}/share/#{group.id}", user)
          end.to not_change { project.reload.project_group_links.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    it 'returns a 400 when group id is not an integer' do
      delete api("/projects/#{project.id}/share/foo", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 404 error when group link does not exist' do
      delete api("/projects/#{project.id}/share/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 error when project does not exist' do
      delete api("/projects/#{non_existing_record_id}/share/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST /projects/:id/restore' do
    let_it_be(:group) { create(:group, owners: user) }
    let_it_be_with_reload(:project) { create(:project, group: group) }

    it 'restores project' do
      project.update!(archived: true, marked_for_deletion_at: 1.day.ago, deleting_user: user)

      post api("/projects/#{project.id}/restore", user)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['archived']).to be_falsey
      expect(json_response['marked_for_deletion_at']).to be_falsey
      expect(json_response['marked_for_deletion_on']).to be_falsey
    end

    it 'returns error if project is already being deleted' do
      message = 'Error'
      expect(::Projects::RestoreService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

      post api("/projects/#{project.id}/restore", user)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response["message"]).to eq(message)
    end
  end

  describe 'POST /projects/:id/import_project_members/:project_id' do
    let_it_be(:project2) { create(:project) }
    let_it_be(:project2_user) { create(:user) }
    let(:path) { "/projects/#{project.id}/import_project_members/#{project2.id}" }

    before_all do
      project.add_maintainer(user)
      project2.add_maintainer(user)
      project2.add_developer(project2_user)
    end

    it 'records the query', :request_store, :use_sql_query_cache do
      post api(path, user)
      expect(response).to have_gitlab_http_status(:created)

      control_project = create(:project)
      control_project.add_maintainer(user)
      control_project.add_developer(create(:user))

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post api("/projects/#{project.id}/import_project_members/#{control_project.id}", user)
      end

      measure_project = create(:project)
      measure_project.add_maintainer(user)
      measure_project.add_developer(create(:user))
      measure_project.add_developer(create(:user)) # make this 2nd one to find any n+1

      unresolved_n_plus_ones = 28 # 28 queries added per member

      expect do
        post api("/projects/#{project.id}/import_project_members/#{measure_project.id}", user)
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end

    it 'returns 200 when it successfully imports members from another project' do
      expect do
        post api(path, user)
      end.to change { project.members.count }.by(2)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['status']).to eq('success')
    end

    it 'returns 404 if the source project does not exist' do
      expect do
        post api("/projects/#{project.id}/import_project_members/#{non_existing_record_id}", user)
      end.not_to change { project.members.count }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Project Not Found')
    end

    it 'returns 404 if the target project members cannot be administered by the requester' do
      private_project = create(:project, :private)

      expect do
        post api("/projects/#{private_project.id}/import_project_members/#{project2.id}", user)
      end.not_to change { project.members.count }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Project Not Found')
    end

    it 'returns 404 if the source project members cannot be viewed by the requester' do
      private_project = create(:project, :private)

      expect do
        post api("/projects/#{project.id}/import_project_members/#{private_project.id}", user)
      end.not_to change { project.members.count }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Project Not Found')
    end

    it 'returns 403 if the source project members cannot be administered by the requester' do
      project.add_maintainer(user2)
      project2.add_developer(user2)

      expect do
        post api(path, user2)
      end.not_to change { project.members.count }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden - Project')
    end

    it 'returns 422 if the import failed for valid projects' do
      allow_next_instance_of(::ProjectTeam) do |project_team|
        allow(project_team).to receive(:import).and_return(false)
      end

      expect do
        post api(path, user)
      end.not_to change { project.members.count }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to eq('Import failed')
      expect(json_response['reason']).to eq('import_failed_error')
    end

    context 'when importing of members did not work for some or all members' do
      it 'fails to import some members' do
        project_bot = create(:user, :project_bot)
        project2.add_developer(project_bot)

        expect do
          post api(path, user)
        end.to change { project.members.count }.by(2)

        expect(response).to have_gitlab_http_status(:created)
        error_message = { project_bot.username => 'User project bots cannot be added to other groups / projects' }
        expect(json_response['message']).to eq(error_message)
        expect(json_response['total_members_count']).to eq(3)
        expect(json_response['status']).to eq('error')
      end
    end
  end

  describe 'PUT /projects/:id' do
    let(:path) { "/projects/#{project.id}" }

    before do
      expect(project).to be_persisted
      expect(user).to be_persisted
      expect(user3).to be_persisted
      expect(user4).to be_persisted
      expect(project3).to be_persisted
      expect(project4).to be_persisted
      expect(project_member2).to be_persisted
      expect(project_member).to be_persisted
    end

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { visibility: 'internal' } }
      let(:failed_status_code) { :not_found }
    end

    describe 'updating ci_push_repository_for_job_token_allowed attribute' do
      it 'is disabled by default' do
        expect(project.ci_push_repository_for_job_token_allowed).to be_falsey
      end

      it 'enables push to repository using job token' do
        put(api(path, user), params: { ci_push_repository_for_job_token_allowed: true })

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.ci_push_repository_for_job_token_allowed).to be_truthy
        expect(json_response['ci_push_repository_for_job_token_allowed']).to eq(true)
      end
    end

    describe 'updating packages_enabled attribute' do
      it 'is enabled by default' do
        expect(project.packages_enabled).to be true
      end

      it 'disables project packages feature' do
        put(api(path, user), params: { packages_enabled: false })

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.packages_enabled).to be false
        expect(json_response['packages_enabled']).to eq(false)
      end
    end

    it 'sets container_registry_access_level' do
      put api(path, user), params: { container_registry_access_level: 'private' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['container_registry_access_level']).to eq('private')
      expect(Project.find_by(path: project[:path]).container_registry_access_level).to eq(ProjectFeature::PRIVATE)
    end

    it 'sets container_registry_enabled' do
      project.project_feature.update!(container_registry_access_level: ProjectFeature::DISABLED)

      put(api(path, user), params: { container_registry_enabled: true })

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['container_registry_enabled']).to eq(true)
      expect(project.reload.container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end

    it 'sets security_and_compliance_access_level' do
      put api(path, user), params: { security_and_compliance_access_level: 'private' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['security_and_compliance_access_level']).to eq('private')
      expect(Project.find_by(path: project[:path]).security_and_compliance_access_level).to eq(ProjectFeature::PRIVATE)
    end

    it 'sets analytics_access_level' do
      put api(path, user), params: { analytics_access_level: 'private' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['analytics_access_level']).to eq('private')
      expect(Project.find_by(path: project[:path]).analytics_access_level).to eq(ProjectFeature::PRIVATE)
    end

    %i[releases_access_level environments_access_level feature_flags_access_level infrastructure_access_level monitor_access_level model_experiments_access_level model_registry_access_level].each do |field|
      it "sets #{field}" do
        put api(path, user), params: { field => 'private' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response[field.to_s]).to eq('private')
        expect(Project.find_by(path: project[:path]).public_send(field)).to eq(ProjectFeature::PRIVATE)
      end
    end

    it 'returns 400 when nothing sent' do
      project_param = {}

      put api(path, user), params: project_param

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to match('at least one parameter must be provided')
    end

    it 'changes the max_artifacts_size attribute' do
      expect(project.max_artifacts_size).to be_nil

      put api(path, admin, admin_mode: true), params: { max_artifacts_size: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(project.reload.max_artifacts_size).to eq(1)
      expect(json_response['max_artifacts_size']).to eq(1)
    end

    it 'does not change the max_artifacts_size attribute when a user does not have permissions' do
      project.add_maintainer(user2)

      put api(path, user2), params: { max_artifacts_size: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(project.reload.max_artifacts_size).not_to eq(1)
      expect(json_response['max_artifacts_size']).not_to eq(1)
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        project_param = { name: 'bar' }

        put api(path), params: project_param

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as project owner' do
      it 'updates visibility_level' do
        project_param = { visibility: 'public' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level from public to private' do
        project3.update!({ visibility_level: Gitlab::VisibilityLevel::PUBLIC })
        project_param = { visibility: 'private' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end

        expect(json_response['visibility']).to eq('private')
      end

      it 'does not update visibility_level if it is restricted' do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

        put api("/projects/#{project3.id}", user), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['visibility_level']).to include('internal has been restricted by your GitLab administrator')
      end

      it 'does not update name to existing name' do
        project_param = { name: project3.name }

        put api(path, user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['name']).to eq(['has already been taken'])
      end

      it 'updates request_access_enabled' do
        project_param = { request_access_enabled: false }

        put api(path, user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['request_access_enabled']).to eq(false)
      end

      it 'updates path & name to existing path & name in different namespace' do
        project_param = { path: project4.path, name: project4.name }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates default_branch' do
        project_param = { default_branch: 'something_else' }

        put api(path, user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates jobs_enabled' do
        project_param = { jobs_enabled: true }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates builds_access_level' do
        project_param = { builds_access_level: 'private' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['builds_access_level']).to eq('private')
      end

      it 'updates pages_access_level' do
        project_param = { pages_access_level: 'private' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['pages_access_level']).to eq('private')
      end

      it 'updates emails_disabled' do
        project_param = { emails_disabled: true }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['emails_disabled']).to eq(true)
      end

      it 'updates emails_enabled?' do
        project_param = { emails_enabled: false }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['emails_enabled']).to eq(false)
      end

      it 'updates build_git_strategy' do
        project_param = { build_git_strategy: 'clone' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['build_git_strategy']).to eq('clone')
      end

      it 'rejects to update build_git_strategy when build_git_strategy is invalid' do
        project_param = { build_git_strategy: 'invalid' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'updates merge_method' do
        project_param = { merge_method: 'ff' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'rejects to update merge_method when merge_method is invalid' do
        project_param = { merge_method: 'invalid' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'when ci_pipeline_variables_minimum_override_role is maintainer' do
        let(:ci_cd_settings) { project3.ci_cd_settings }

        before do
          project3.add_maintainer(user2)
          ci_cd_settings.pipeline_variables_minimum_override_role = 'maintainer'
          ci_cd_settings.save!
        end

        context 'and resrict_user_defined_variables is true' do
          context 'and current user is maintainer' do
            let_it_be(:current_user) { user2 }

            it 'accepts to change restrict_user_defined_variables' do
              project_param = { restrict_user_defined_variables: false }

              expect do
                put api("/projects/#{project3.id}", current_user), params: project_param
              end.to change { ci_cd_settings.reload.restrict_user_defined_variables? }.from(true).to(false)
              .and change { ci_cd_settings.pipeline_variables_minimum_override_role }.from('maintainer').to('developer')

              expect(response).to have_gitlab_http_status(:ok)
              response_data = Gitlab::Json.parse(response.body)
              expect(response_data['restrict_user_defined_variables']).to be_falsey
            end
          end
        end
      end

      context 'when ci_pipeline_variables_minimum_override_role is developer' do
        let(:ci_cd_settings) { project3.ci_cd_settings }

        before do
          project3.add_maintainer(user2)
          ci_cd_settings.pipeline_variables_minimum_override_role = 'developer'
          ci_cd_settings.save!
        end

        context 'and current user is maintainer' do
          let_it_be(:current_user) { user2 }

          it 'accepts to change restrict_user_defined_variables' do
            project_param = { restrict_user_defined_variables: true }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'accepts to change ci_pipeline_variables_minimum_override_role' do
            project_param = { ci_pipeline_variables_minimum_override_role: 'developer' }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'and current user is owner' do
          let_it_be(:current_user) { user }

          it 'successfully changes restrict_user_defined_variables' do
            project_param = { restrict_user_defined_variables: true }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'successfully changes ci_pipeline_variables_minimum_override_role' do
            project_param = { ci_pipeline_variables_minimum_override_role: 'developer' }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'when ci_pipeline_variables_minimum_override_role is set to developer' do
        before do
          project3.add_maintainer(user2)
          ci_cd_settings = project3.ci_cd_settings
          ci_cd_settings.pipeline_variables_minimum_override_role = 'developer'
          ci_cd_settings.save!
        end

        context 'and current user is maintainer' do
          let_it_be(:current_user) { user2 }

          it 'successfully changes restrict_user_defined_variables' do
            project_param = { restrict_user_defined_variables: true }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'successfully changes ci_pipeline_variables_minimum_override_role' do
            project_param = { ci_pipeline_variables_minimum_override_role: 'maintainer' }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'rejects to ci_pipeline_variables_minimum_override_role to owner' do
            project_param = { ci_pipeline_variables_minimum_override_role: 'owner' }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'and current user is developer' do
          let_it_be(:current_user) { user3 }

          before do
            project3.add_developer(user3)
          end

          it 'fails to change restrict_user_defined_variables' do
            project_param = { restrict_user_defined_variables: true }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:forbidden)
          end

          it 'fails to change ci_pipeline_variables_minimum_override_role' do
            project_param = { ci_pipeline_variables_minimum_override_role: 'developer' }

            put api("/projects/#{project3.id}", current_user), params: project_param

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      it 'updates restrict_user_defined_variables' do
        project_param = { restrict_user_defined_variables: true }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates ci_pipeline_variables_minimum_override_role' do
        project_param = { ci_pipeline_variables_minimum_override_role: 'owner' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'rejects updating ci_pipeline_variables_minimum_override_role when an invalid role is provided' do
        project_param = { ci_pipeline_variables_minimum_override_role: 'wrong' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects updating ci_pipeline_variables_minimum_override_role when an existing but not allowed role is provided' do
        project_param = { ci_pipeline_variables_minimum_override_role: 'guest' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'updates public_builds (deprecated)' do
        project3.update!({ public_builds: false })
        project_param = { public_builds: 'true' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['public_jobs']).to be_truthy
      end

      it 'updates public_jobs' do
        project3.update!({ public_builds: false })
        project_param = { public_jobs: 'true' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['public_jobs']).to be_truthy
      end

      context 'with changes to the avatar' do
        let_it_be(:avatar_file) { fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }
        let_it_be(:alternate_avatar_file) { fixture_file_upload('spec/fixtures/rails_sample.png', 'image/png') }
        let_it_be(:project_with_avatar, reload: true) do
          create(
            :project,
            :private,
            :repository,
            name: 'project-with-avatar',
            creator_id: user.id,
            namespace: user.namespace,
            avatar: avatar_file
          )
        end

        it 'uploads avatar to project without an avatar' do
          workhorse_form_with_file(
            api("/projects/#{project3.id}", user),
            method: :put,
            file_key: :avatar,
            params: { avatar: avatar_file }
          )

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['avatar_url']).to eq('http://localhost/uploads/' \
                                                      '-/system/project/avatar/' \
                                                      "#{project3.id}/banana_sample.gif")
          end
        end

        it 'uploads and changes avatar to project with an avatar' do
          workhorse_form_with_file(
            api("/projects/#{project_with_avatar.id}", user),
            method: :put,
            file_key: :avatar,
            params: { avatar: alternate_avatar_file }
          )

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['avatar_url']).to eq('http://localhost/uploads/' \
                                                      '-/system/project/avatar/' \
                                                      "#{project_with_avatar.id}/rails_sample.png")
          end
        end

        it 'uploads and changes avatar to project among other changes' do
          workhorse_form_with_file(
            api("/projects/#{project_with_avatar.id}", user),
            method: :put,
            file_key: :avatar,
            params: { description: 'changed description', avatar: avatar_file }
          )

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['description']).to eq('changed description')
            expect(json_response['avatar_url']).to eq('http://localhost/uploads/' \
                                                      '-/system/project/avatar/' \
                                                      "#{project_with_avatar.id}/banana_sample.gif")
          end
        end

        it 'removes avatar from project with an avatar' do
          put api("/projects/#{project_with_avatar.id}", user), params: { avatar: '' }

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['avatar_url']).to be_nil
            expect(project_with_avatar.reload.avatar_url).to be_nil
          end
        end
      end

      it 'updates auto_devops_deploy_strategy' do
        project_param = { auto_devops_deploy_strategy: 'timed_incremental' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['auto_devops_deploy_strategy']).to eq('timed_incremental')
      end

      it 'updates auto_devops_enabled' do
        project_param = { auto_devops_enabled: false }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['auto_devops_enabled']).to eq(false)
      end

      it 'updates topics using tag_list (deprecated)' do
        project_param = { tag_list: 'topic1' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['topics']).to eq(%w[topic1])
      end

      it 'updates topics' do
        project_param = { topics: 'topic2' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['topics']).to eq(%w[topic2])
      end

      it 'updates the merge_request_title_regex and description' do
        project3.update!(merge_request_title_regex: nil)

        project_param = { merge_request_title_regex: '/aaa/', merge_request_title_regex_description: 'Description of regex' }

        expect { put api("/projects/#{project3.id}", user), params: project_param }
          .to change { [project3.reload.merge_request_title_regex, project3.merge_request_title_regex_description] }
          .from([nil, nil])
          .to([/aaa/, "Description of regex"])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['merge_request_title_regex']).to eq("/aaa/")
        expect(json_response['merge_request_title_regex_description']).to eq("Description of regex")
      end

      it 'updates enforce_auth_checks_on_uploads' do
        project3.update!(enforce_auth_checks_on_uploads: false)

        project_param = { enforce_auth_checks_on_uploads: true }

        expect { put api("/projects/#{project3.id}", user), params: project_param }
          .to change { project3.reload.enforce_auth_checks_on_uploads }
          .from(false)
          .to(true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['enforce_auth_checks_on_uploads']).to eq(true)
      end

      it 'updates squash_option' do
        project3.update!(squash_option: 'always')

        project_param = { squash_option: "default_on" }

        expect { put api("/projects/#{project3.id}", user), params: project_param }
          .to change { project3.reload.squash_option }
          .from('always')
          .to('default_on')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['squash_option']).to eq("default_on")
      end

      it 'does not update an invalid squash_option' do
        project_param = { squash_option: "jawn" }

        expect { put api("/projects/#{project3.id}", user), params: project_param }
          .not_to change { project3.reload.squash_option }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'updates ci_delete_pipelines_in_seconds' do
        project_param = { ci_delete_pipelines_in_seconds: 1.week.to_i }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['ci_delete_pipelines_in_seconds']).to eq(1.week.to_i)
      end

      it 'clears ci_delete_pipelines_in_seconds' do
        project3.update!(ci_delete_pipelines_in_seconds: 1.week.to_i)

        project_param = { ci_delete_pipelines_in_seconds: nil }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match(a_hash_including('ci_delete_pipelines_in_seconds' => nil))
      end
    end

    context 'when authenticated as project maintainer' do
      it 'updates path' do
        project_param = { path: 'bar' }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(:ok)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates other attributes' do
        project_param = { issues_enabled: true,
                          wiki_enabled: true,
                          snippets_enabled: true,
                          merge_requests_enabled: true,
                          merge_method: 'ff',
                          ci_default_git_depth: 20,
                          ci_forward_deployment_enabled: false,
                          ci_forward_deployment_rollback_allowed: false,
                          ci_allow_fork_pipelines_to_run_in_parent_project: false,
                          ci_separated_caches: false,
                          description: 'new description' }

        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(:ok)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'does not update path to existing path' do
        project_param = { path: project.path }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'updates name' do
        project_param = { name: 'bar' }

        put api(path, user), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'does not update visibility_level' do
        project_param = { visibility: 'public' }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates container_expiration_policy' do
        project_param = {
          container_expiration_policy_attributes: {
            cadence: '1month',
            keep_n: 1,
            name_regex_keep: 'foo.*'
          }
        }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['container_expiration_policy']['cadence']).to eq('1month')
        expect(json_response['container_expiration_policy']['keep_n']).to eq(1)
        expect(json_response['container_expiration_policy']['name_regex_keep']).to eq('foo.*')
      end

      it "doesn't update container_expiration_policy with invalid regex" do
        project_param = {
          container_expiration_policy_attributes: {
            cadence: '1month',
            enabled: true,
            keep_n: 1,
            name_regex_keep: '['
          }
        }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['container_expiration_policy.name_regex_keep']).to contain_exactly('not valid RE2 syntax: missing ]: [')
      end

      it "doesn't update container_expiration_policy with invalid keep_n" do
        project_param = {
          container_expiration_policy_attributes: {
            cadence: '1month',
            enabled: true,
            keep_n: 'not_int',
            name_regex_keep: 'foo.*'
          }
        }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('container_expiration_policy_attributes[keep_n] is invalid')
      end

      it "doesn't update ci_delete_pipelines_in_seconds" do
        project_param = { ci_delete_pipelines_in_seconds: 1.week.to_i }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(project3.reload.ci_delete_pipelines_in_seconds).to be_nil
      end

      it "doesn't remove ci_delete_pipelines_in_seconds" do
        project3.update!(ci_delete_pipelines_in_seconds: 1.week.to_i)
        project_param = { ci_delete_pipelines_in_seconds: nil }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(project3.reload.ci_delete_pipelines_in_seconds).to eq(1.week)
      end
    end

    context 'with repository_object_format' do
      it 'ignores repository object format field' do
        put api(path, user), params: { name: 'new', repository_object_format: 'sha256' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['repository_object_format']).to eq 'sha1'
      end
    end

    context 'with initialize_with_readme' do
      it 'ignores initialize_with_readme field' do
        put api(path, user), params: { name: 'new', initialize_with_readme: true }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when authenticated as project developer' do
      it 'does not update other attributes' do
        project_param = { path: 'bar',
                          issues_enabled: true,
                          wiki_enabled: true,
                          snippets_enabled: true,
                          merge_requests_enabled: true,
                          description: 'new description',
                          request_access_enabled: true }
        put api(path, user3), params: project_param
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as the admin' do
      let_it_be(:admin) { create(:admin) }

      it 'ignores visibility level restrictions' do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

        put api("/projects/#{project3.id}", admin, admin_mode: true), params: { visibility: 'internal' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['visibility']).to eq('internal')
      end
    end

    context 'when updating repository storage' do
      let(:unknown_storage) { 'new-storage' }
      let(:new_project) { create(:project, :repository, namespace: user.namespace) }

      context 'as a user' do
        it 'returns 200 but does not change repository_storage' do
          expect do
            Sidekiq::Testing.fake! do
              put(api("/projects/#{new_project.id}", user), params: { repository_storage: unknown_storage, issues_enabled: false })
            end
          end.not_to change(Projects::UpdateRepositoryStorageWorker.jobs, :size)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['issues_enabled']).to eq(false)
          expect(new_project.reload.repository.storage).to eq('default')
        end
      end

      context 'as an admin' do
        include_context 'custom session'

        let(:admin) { create(:admin) }

        it 'returns 400 when repository storage is unknown' do
          put(api("/projects/#{new_project.id}", admin, admin_mode: true), params: { repository_storage: unknown_storage })

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['repository_storage_moves']).to eq(['is invalid'])
        end

        it 'returns 200 when repository storage has changed' do
          stub_storage_settings('test_second_storage' => {})

          expect do
            Sidekiq::Testing.fake! do
              put(api("/projects/#{new_project.id}", admin, admin_mode: true), params: { repository_storage: 'test_second_storage' })
            end
          end.to change(Projects::UpdateRepositoryStorageWorker.jobs, :size).by(1)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when updating service desk' do
      let(:params) { { service_desk_enabled: true } }

      subject(:request) { put(api(path, user), params: params) }

      before do
        project.update!(service_desk_enabled: false)

        allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
      end

      it 'returns 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'enables the service_desk' do
        expect { request }.to change { project.reload.service_desk_enabled }.to(true)
      end
    end

    context 'when updating keep latest artifact' do
      subject(:request) { put(api(path, user), params: { keep_latest_artifact: true }) }

      before do
        project.update!(keep_latest_artifact: false)
      end

      it 'returns 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'enables keep_latest_artifact' do
        expect { request }.to change { project.reload.keep_latest_artifact }.to(true)
      end
    end

    context 'attribute mr_default_target_self' do
      let_it_be(:source_project) { create(:project, :public) }

      let(:forked_project) { fork_project(source_project, user) }

      it 'is by default set to false' do
        expect(source_project.mr_default_target_self).to be false
        expect(forked_project.mr_default_target_self).to be false
      end

      describe 'for a non-forked project' do
        before_all do
          source_project.add_maintainer(user)
        end

        it 'is not exposed' do
          get api("/projects/#{source_project.id}", user)

          expect(json_response).not_to include('mr_default_target_self')
        end

        it 'is not possible to update' do
          put api("/projects/#{source_project.id}", user), params: { mr_default_target_self: true }

          source_project.reload
          expect(source_project.mr_default_target_self).to be false
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      describe 'for a forked project' do
        it 'updates to true' do
          put api("/projects/#{forked_project.id}", user), params: { mr_default_target_self: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['mr_default_target_self']).to eq(true)
        end
      end
    end
  end

  describe 'POST /projects/:id/archive' do
    let(:path) { "/projects/#{project.id}/archive" }

    context 'on an unarchived project' do
      it 'archives the project' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'on an archived project' do
      before do
        ::Projects::UpdateService.new(project, user, archived: true).execute
      end

      it 'remains archived' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.add_developer(user3)
      end

      it 'rejects the action' do
        post api(path, user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when a project is moved' do
      let_it_be(:redirect_route) { 'new/project/location' }
      let_it_be(:path) { "/projects/#{CGI.escape(redirect_route)}/archive" }

      before do
        project.route.create_redirect(redirect_route)
      end

      it 'returns 405 error' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:method_not_allowed)
      end

      context 'when user do not have access to the project' do
        it 'returns 404 error' do
          post api(path, create(:user))

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /projects/:id/unarchive' do
    let(:path) { "/projects/#{project.id}/unarchive" }

    context 'on an unarchived project' do
      it 'remains unarchived' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'on an archived project' do
      before do
        ::Projects::UpdateService.new(project, user, archived: true).execute
      end

      it 'unarchives the project' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.add_developer(user3)
      end

      it 'rejects the action' do
        post api(path, user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/:id/star' do
    let(:path) { "/projects/#{project.id}/star" }

    context 'on an unstarred project' do
      it 'stars the project' do
        expect { post api(path, user) }.to change { project.reload.star_count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['star_count']).to eq(1)
      end
    end

    context 'on a starred project' do
      before do
        user.toggle_star(project)
        project.reload
      end

      it 'does not modify the star count' do
        expect { post api(path, user) }.not_to change { project.reload.star_count }

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'POST /projects/:id/unstar' do
    let(:path) { "/projects/#{project.id}/unstar" }

    context 'on a starred project' do
      before do
        user.toggle_star(project)
        project.reload
      end

      it 'unstars the project' do
        expect { post api(path, user) }.to change { project.reload.star_count }.by(-1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['star_count']).to eq(0)
      end
    end

    context 'on an unstarred project' do
      it 'does not modify the star count' do
        expect { post api(path, user) }.not_to change { project.reload.star_count }

        expect(response).to have_gitlab_http_status(:not_modified)
      end
    end
  end

  describe 'GET /projects/:id/starrers' do
    let(:path) { "/projects/#{public_project.id}/starrers" }
    let(:public_project) { create(:project, :public) }
    let(:private_user) { create(:user, private_profile: true) }

    shared_examples_for 'project starrers response' do
      it 'returns an array of starrers' do
        get api(path, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response[0]['starred_since']).to be_present
        expect(json_response[0]['user']).to be_present
      end

      it 'returns the proper security headers' do
        get api(path, current_user)

        expect(response).to include_security_headers
      end
    end

    before do
      user.users_star_projects.create!(project_id: public_project.id)
      private_user.users_star_projects.create!(project_id: public_project.id)
    end

    it 'returns not_found(404) for not existing project' do
      get api("/projects/#{non_existing_record_id}/starrers", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'public project without user' do
      it_behaves_like 'project starrers response' do
        let(:current_user) { nil }
      end

      it 'returns only starrers with a public profile' do
        get api(path, nil)

        user_ids = json_response.map { |s| s['user']['id'] }
        expect(user_ids).to include(user.id)
        expect(user_ids).not_to include(private_user.id)
      end
    end

    context 'public project with user with private profile' do
      it_behaves_like 'project starrers response' do
        let(:current_user) { private_user }
      end

      it 'returns current user with a private profile' do
        get api(path, private_user)

        user_ids = json_response.map { |s| s['user']['id'] }
        expect(user_ids).to include(user.id, private_user.id)
      end
    end

    context 'private project' do
      context 'with unauthorized user' do
        it 'returns not_found for existing but unauthorized project' do
          get api("/projects/#{project3.id}/starrers", user3)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'without user' do
        it 'returns not_found for existing but unauthorized project' do
          get api("/projects/#{project3.id}/starrers", nil)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/languages' do
    context 'with an authorized user' do
      it_behaves_like 'languages and percentages JSON response' do
        let(:project) { project3 }
      end

      it 'returns not_found(404) for not existing project' do
        get api("/projects/#{non_existing_record_id}/languages", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with not authorized user' do
      it 'returns not_found for existing but unauthorized project' do
        get api("/projects/#{project3.id}/languages", user3)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without user' do
      let(:project_public) { create(:project, :public, :repository) }

      it_behaves_like 'languages and percentages JSON response' do
        let(:project) { project_public }
      end

      it 'returns not_found for existing but unauthorized project' do
        get api("/projects/#{project3.id}/languages", nil)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id' do
    let(:path) { "/projects/#{project.id}" }

    it_behaves_like 'DELETE request permissions for admin mode' do
      let(:success_status_code) { :accepted }
      let(:failed_status_code) { :not_found }
    end

    context 'when authenticated as user' do
      it 'removes project' do
        delete api(path, user)

        expect(response).to have_gitlab_http_status(:accepted)
        expect(json_response['message']).to eql('202 Accepted')
      end

      it_behaves_like '412 response' do
        let(:success_status) { 202 }
        subject(:request) { api(path, user) }
      end

      it 'does not remove a project if not an owner' do
        user3 = create(:user)
        project.add_developer(user3)
        delete api(path, user3)
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not remove a non existing project' do
        delete api("/projects/#{non_existing_record_id}", user)
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not remove a project not attached to user' do
        delete api(path, user2)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as admin' do
      it 'removes any existing project' do
        delete api("/projects/#{project.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:accepted)
        expect(json_response['message']).to eql('202 Accepted')
      end

      it 'does not remove a non existing project' do
        delete api("/projects/#{non_existing_record_id}", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:success_status) { 202 }
        subject(:request) { api("/projects/#{project.id}", admin, admin_mode: true) }
      end
    end

    shared_examples 'deletes project immediately' do
      it :aggregate_failures do
        expect(::Projects::DestroyService).to receive(:new).with(project, user, {}).and_call_original

        delete api(path, user), params: params
        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    shared_examples 'immediately delete project error' do
      it :aggregate_failures do
        expect(::Projects::DestroyService).not_to receive(:new)
        expect(::Projects::MarkForDeletionService).not_to receive(:new)

        delete api(path, user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(Gitlab::Json.parse(response.body)['message']).to eq(error_message)
      end
    end

    context 'for delayed deletion' do
      let_it_be(:group) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, group: group, owners: user) }
      let(:params) { {} }

      it 'marks the project for deletion' do
        expect(::Projects::MarkForDeletionService).to receive(:new).with(project, user, {}).and_call_original

        delete api(path, user), params: params

        expect(response).to have_gitlab_http_status(:accepted)
        expect(project.reload.self_deletion_scheduled?).to be_truthy
      end

      it 'returns error if project cannot be marked for deletion' do
        message = 'Error'
        expect(::Projects::MarkForDeletionService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

        delete api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["message"]).to eq(message)
      end

      context 'when permanently_remove param is true' do
        before do
          params.merge!(permanently_remove: true)
        end

        context 'when project is already marked for deletion' do
          before do
            project.update!(archived: true, marked_for_deletion_at: 1.day.ago, deleting_user: user)
          end

          context 'with correct project full path' do
            before do
              params.merge!(full_path: project.full_path)
            end

            it_behaves_like 'deletes project immediately'
          end

          context 'with incorrect project full path' do
            let(:error_message) { '`full_path` is incorrect. You must enter the complete path for the project.' }

            before do
              params.merge!(full_path: "#{project.full_path}-wrong-path")
            end

            it_behaves_like 'immediately delete project error'
          end
        end

        context 'when project is not marked for deletion' do
          let(:error_message) { 'Project must be marked for deletion first.' }

          it_behaves_like 'immediately delete project error'
        end
      end
    end
  end

  describe 'POST /projects/:id/fork' do
    let(:project) do
      create(:project, :repository, creator: user, namespace: user.namespace)
    end

    let(:path) { "/projects/#{project.id}/fork" }

    let(:project2) do
      create(:project, :repository, creator: user, namespace: user.namespace)
    end

    let(:group) { create(:group, :public) }
    let(:group2) { create(:group, name: 'group2_name') }
    let(:group3) { create(:group, name: 'group3_name', parent: group2) }

    before do
      group.add_guest(user2)
      group2.add_maintainer(user2)
      group3.add_owner(user2)
      project.add_reporter(user2)
      project2.add_reporter(user2)
    end

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { {} }
      let(:failed_status_code) { :not_found }
    end

    context 'when authenticated' do
      it 'forks if user has sufficient access to project' do
        post api(path, user2)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'forks if user is admin' do
        post api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(admin.id)
        expect(json_response['namespace']['id']).to eq(admin.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'fails on missing project access for the project to fork' do
        new_user = create(:user)
        post api(path, new_user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'fails if forked project exists in the user namespace' do
        new_project = create(:project, name: project.name, path: project.path)
        new_project.add_reporter(user)

        post api("/projects/#{new_project.id}/fork", user)

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to match_array(
          [
            'Name has already been taken',
            'Path has already been taken',
            'Project namespace name has already been taken'
          ]
        )
      end

      it 'fails if project to fork from does not exist' do
        post api("/projects/#{non_existing_record_id}/fork", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'forks with explicit own user namespace id' do
        post api(path, user2), params: { namespace: user2.namespace.id }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks with explicit own user name as namespace' do
        post api(path, user2), params: { namespace: user2.username }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks to another user when admin' do
        post api(path, admin, admin_mode: true), params: { namespace: user2.username }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'fails if trying to fork to another user when not admin' do
        post api(path, user2), params: { namespace: admin.namespace.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'fails if trying to fork to non-existent namespace' do
        post api(path, user2), params: { namespace: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Namespace Not Found')
      end

      it 'forks to owned group' do
        post api(path, user2), params: { namespace: group2.name }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['namespace']['name']).to eq(group2.name)
      end

      context 'when namespace_id is specified' do
        shared_examples_for 'forking to specified namespace_id' do
          it 'forks to specified namespace_id' do
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['owner']['id']).to eq(user2.id)
            expect(json_response['namespace']['id']).to eq(user2.namespace.id)
          end
        end

        context 'and namespace_id is specified alone' do
          before do
            post api(path, user2), params: { namespace_id: user2.namespace.id }
          end

          it_behaves_like 'forking to specified namespace_id'
        end

        context 'and namespace_id and namespace are both specified' do
          before do
            post api(path, user2), params: { namespace_id: user2.namespace.id, namespace: admin.namespace.id }
          end

          it_behaves_like 'forking to specified namespace_id'
        end

        context 'and namespace_id and namespace_path are both specified' do
          before do
            post api(path, user2), params: { namespace_id: user2.namespace.id, namespace_path: admin.namespace.path }
          end

          it_behaves_like 'forking to specified namespace_id'
        end
      end

      context 'when namespace_path is specified' do
        shared_examples_for 'forking to specified namespace_path' do
          it 'forks to specified namespace_path' do
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['owner']['id']).to eq(user2.id)
            expect(json_response['namespace']['path']).to eq(user2.namespace.path)
          end
        end

        context 'and namespace_path is specified alone' do
          before do
            post api(path, user2), params: { namespace_path: user2.namespace.path }
          end

          it_behaves_like 'forking to specified namespace_path'
        end

        context 'and namespace_path and namespace are both specified' do
          before do
            post api(path, user2), params: { namespace_path: user2.namespace.path, namespace: admin.namespace.path }
          end

          it_behaves_like 'forking to specified namespace_path'
        end
      end

      it 'forks to owned subgroup' do
        full_path = "#{group2.path}/#{group3.path}"
        post api(path, user2), params: { namespace: full_path }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['namespace']['name']).to eq(group3.name)
        expect(json_response['namespace']['full_path']).to eq(full_path)
      end

      it 'fails to fork to not owned group' do
        post api(path, user2), params: { namespace: group.name }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq("404 Target Namespace Not Found")
      end

      it 'forks to not owned group when admin' do
        post api(path, admin, admin_mode: true), params: { namespace: group.name }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['namespace']['name']).to eq(group.name)
      end

      it 'accepts a path for the target project' do
        post api(path, user2), params: { path: 'foobar' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq('foobar')
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'fails to fork if path is already taken' do
        post api(path, user2), params: { path: 'foobar' }
        post api("/projects/#{project2.id}/fork", user2), params: { path: 'foobar' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to eq(['Path has already been taken'])
      end

      it 'accepts custom parameters for the target project' do
        post api(path, user2),
          params: {
            name: 'My Random Project',
            description: 'A description',
            visibility: 'private',
            mr_default_target_self: true
          }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('My Random Project')
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['description']).to eq('A description')
        expect(json_response['visibility']).to eq('private')
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response['mr_default_target_self']).to eq(true)
        expect(json_response).to include("import_error")
      end

      it 'fails to fork if name is already taken' do
        post api(path, user2), params: { name: 'My Random Project' }
        post api("/projects/#{project2.id}/fork", user2), params: { name: 'My Random Project' }

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to match_array(
          [
            'Name has already been taken',
            'Project namespace name has already been taken'
          ]
        )
      end

      it 'forks to the same namespace with alternative path and name' do
        post api(path, user), params: { path: 'path_2', name: 'name_2' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('name_2')
        expect(json_response['path']).to eq('path_2')
        expect(json_response['owner']['id']).to eq(user.id)
        expect(json_response['namespace']['id']).to eq(user.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
      end

      it 'fails to fork to the same namespace without alternative path and name' do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['message']).to match_array(
          [
            'Name has already been taken',
            'Path has already been taken',
            'Project namespace name has already been taken'
          ]
        )
      end

      it 'fails to fork with an unknown visibility level' do
        post api(path, user2), params: { visibility: 'something' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('visibility does not have a valid value')
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['message']).to eq('401 Unauthorized')
      end
    end

    context 'forking disabled' do
      before do
        project.project_feature.update_attribute(
          :forking_access_level, ProjectFeature::DISABLED)
      end

      it 'denies project to be forked' do
        post api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/housekeeping' do
    let(:housekeeping) { ::Repositories::HousekeepingService.new(project) }
    let(:params) { {} }
    let(:path) { "/projects/#{project.id}/housekeeping" }

    subject(:request) { post api(path, user), params: params }

    before do
      allow(::Repositories::HousekeepingService).to receive(:new).with(project, :eager).and_return(housekeeping)
    end

    context 'when authenticated as owner' do
      it 'starts the housekeeping process' do
        expect(housekeeping).to receive(:execute).once

        request

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'logs an audit event' do
        expect(housekeeping).to receive(:execute).once.and_yield
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(a_hash_including(
          name: 'manually_trigger_housekeeping',
          author: user,
          scope: project,
          target: project,
          message: "Housekeeping task: eager"
        ))

        request
      end

      context 'when requesting prune' do
        let(:params) { { task: :prune } }

        it 'triggers a prune' do
          expect(::Repositories::HousekeepingService).to receive(:new).with(project, :prune).and_return(housekeeping)
          expect(housekeeping).to receive(:execute).once

          request

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when requesting an unsupported task' do
        let(:params) { { task: :unsupported_task } }

        it 'responds with bad_request' do
          expect(::Repositories::HousekeepingService).not_to receive(:new)

          request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when housekeeping lease is taken' do
        it 'returns conflict' do
          expect(housekeeping).to receive(:execute).once.and_raise(::Repositories::HousekeepingService::LeaseTaken)

          request

          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to match(/Somebody already triggered housekeeping for this resource/)
        end
      end
    end

    context 'when authenticated as developer' do
      before do
        project_member
      end

      it 'returns forbidden error' do
        post api(path, user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/repository_size' do
    let(:update_statistics_service) { Projects::UpdateStatisticsService.new(project, nil, statistics: [:repository_size, :lfs_objects_size]) }
    let(:path) { "/projects/#{project.id}/repository_size" }

    before do
      allow(Projects::UpdateStatisticsService).to receive(:new).with(project, nil, statistics: [:repository_size, :lfs_objects_size]).and_return(update_statistics_service)
    end

    context 'when authenticated as owner' do
      it 'starts the housekeeping process' do
        expect(update_statistics_service).to receive(:execute).once

        post api(path, user)

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when authenticated as developer' do
      before do
        project_member
      end

      it 'returns forbidden error' do
        post api(path, user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /projects/:id/transfer' do
    let(:path) { "/projects/#{project.id}/transfer" }

    context 'when authenticated as owner' do
      let(:group) { create :group }

      it 'transfers the project to the new namespace' do
        group.add_owner(user)

        put api(path, user), params: { namespace: group.id }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'fails when transferring to a non owned namespace' do
        put api(path, user), params: { namespace: group.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'fails when transferring to an unknown namespace' do
        put api(path, user), params: { namespace: 'unknown' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'fails on missing namespace' do
        put api(path, user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when authenticated as developer' do
      before do
        group.add_developer(user)
      end

      context 'target namespace allows developers to create projects' do
        let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS) }

        it 'fails transferring the project to the target namespace' do
          put api(path, user), params: { namespace: group.id }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe 'GET /projects/:id/transfer_locations' do
    let_it_be(:user) { create(:user) }
    let_it_be(:source_group) { create(:group) }
    let_it_be(:project) { create(:project, group: source_group) }

    let(:params) { {} }

    subject(:request) do
      get api("/projects/#{project.id}/transfer_locations", user), params: params
    end

    context 'when the user has rights to transfer the project' do
      let_it_be(:guest_group) { create(:group) }
      let_it_be(:maintainer_group) { create(:group, name: 'maintainer group', path: 'maintainer-group') }
      let_it_be(:owner_group) { create(:group, name: 'owner group', path: 'owner-group') }

      before do
        source_group.add_owner(user)
        guest_group.add_guest(user)
        maintainer_group.add_maintainer(user)
        owner_group.add_owner(user)
      end

      it 'returns 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
      end

      it 'includes groups where the user has permissions to transfer a project to' do
        request

        expect(project_ids_from_response).to match_array [maintainer_group.id, owner_group.id]
      end

      it 'does not include groups where the user doesn not have permissions to transfer a project' do
        request

        expect(project_ids_from_response).not_to include(guest_group.id)
      end

      it 'does not include the group id of the current project' do
        request

        expect(project_ids_from_response).not_to include(project.group.id)
      end

      context 'with search' do
        let(:params) { { search: 'maintainer' } }

        it 'includes groups where the user has permissions to transfer a project to' do
          request

          expect(project_ids_from_response).to contain_exactly(maintainer_group.id)
        end
      end

      context 'group shares' do
        let_it_be(:shared_to_owner_group) { create(:group) }
        let_it_be(:shared_to_guest_group) { create(:group) }

        before do
          create(:group_group_link, :owner, shared_with_group: owner_group, shared_group: shared_to_owner_group)
          create(:group_group_link, :guest, shared_with_group: guest_group, shared_group: shared_to_guest_group)
        end

        it 'only includes groups arising from group shares where the user has permission to transfer a project to' do
          request

          expect(project_ids_from_response).to include(shared_to_owner_group.id)
          expect(project_ids_from_response).not_to include(shared_to_guest_group.id)
        end
      end

      def project_ids_from_response
        json_response.map { |project| project['id'] }
      end
    end

    context 'when the user does not have permissions to transfer the project' do
      before do
        source_group.add_developer(user)
      end

      it 'returns 403' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/storage' do
    let(:path) { "/projects/#{project.id}/storage" }

    it_behaves_like 'GET request permissions for admin mode'

    context 'when unauthenticated' do
      it 'does not return project storage data' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it 'returns project storage data when user is admin' do
      get api(path, create(:admin), admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['project_id']).to eq(project.id)
      expect(json_response['disk_path']).to eq(project.repository.disk_path)
      expect(json_response['created_at']).to be_present
      expect(json_response['repository_storage']).to eq(project.repository_storage)
    end

    it 'does not return project storage data when user is not admin' do
      get api(path, user3)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'responds with a 401 for unauthenticated users trying to access a non-existent project id' do
      expect(Project.find_by(id: non_existing_record_id)).to be_nil

      get api("/projects/#{non_existing_record_id}/storage")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'responds with a 403 for non-admin users trying to access a non-existent project id' do
      expect(Project.find_by(id: non_existing_record_id)).to be_nil

      get api("/projects/#{non_existing_record_id}/storage", user3)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  it_behaves_like 'custom attributes endpoints', 'projects' do
    let(:attributable) { project }
    let(:other_attributable) { project2 }
  end
end
