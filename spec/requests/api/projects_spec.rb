# -*- coding: utf-8 -*-
require 'spec_helper'

shared_examples 'languages and percentages JSON response' do
  let(:expected_languages) { project.repository.languages.map { |language| language.values_at(:label, :value)}.to_h }

  it 'returns expected language values' do
    get api("/projects/#{project.id}/languages", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to eq(expected_languages)
    expect(json_response.count).to be > 1
  end
end

describe API::Projects do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:project2) { create(:project, namespace: user.namespace) }
  let(:snippet) { create(:project_snippet, :public, author: user, project: project, title: 'example') }
  let(:project_member) { create(:project_member, :developer, user: user3, project: project) }
  let(:user4) { create(:user) }
  let(:project3) do
    create(:project,
    :private,
    :repository,
    name: 'second_project',
    path: 'second_project',
    creator_id: user.id,
    namespace: user.namespace,
    merge_requests_enabled: false,
    issues_enabled: false, wiki_enabled: false,
    builds_enabled: false,
    snippets_enabled: false)
  end
  let(:project_member2) do
    create(:project_member,
    user: user4,
    project: project3,
    access_level: ProjectMember::MASTER)
  end
  let(:project4) do
    create(:project,
    name: 'third_project',
    path: 'third_project',
    creator_id: user4.id,
    namespace: user4.namespace)
  end

  describe 'GET /projects' do
    shared_examples_for 'projects response' do
      it 'returns an array of projects' do
        get api('/projects', current_user), filter

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(*projects.map(&:id))
      end

      it 'returns the proper security headers' do
        get api('/projects', current_user), filter

        expect(response).to include_security_headers
      end
    end

    shared_examples_for 'projects response without N + 1 queries' do
      it 'avoids N + 1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          get api('/projects', current_user)
        end

        if defined?(additional_project)
          additional_project
        else
          create(:project, :public)
        end

        # TODO: We're currently querying to detect if a project is a fork
        # in 2 ways. Lower this back to 8 when `ForkedProjectLink` relation is
        # removed
        expect do
          get api('/projects', current_user)
        end.not_to exceed_query_limit(control).with_threshold(9)
      end
    end

    let!(:public_project) { create(:project, :public, name: 'public_project') }
    before do
      project
      project2
      project3
      project4
    end

    context 'when unauthenticated' do
      it_behaves_like 'projects response' do
        let(:filter) { { search: project.name } }
        let(:current_user) { user }
        let(:projects) { [project] }
      end

      it_behaves_like 'projects response without N + 1 queries' do
        let(:current_user) { nil }
      end
    end

    context 'when authenticated as regular user' do
      it_behaves_like 'projects response' do
        let(:filter) { {} }
        let(:current_user) { user }
        let(:projects) { [public_project, project, project2, project3] }
      end

      it_behaves_like 'projects response without N + 1 queries' do
        let(:current_user) { user }
      end

      context 'when some projects are in a group' do
        before do
          create(:project, :public, group: create(:group))
        end

        it_behaves_like 'projects response without N + 1 queries' do
          let(:current_user) { user }
          let(:additional_project) { create(:project, :public, group: create(:group)) }
        end
      end

      it 'includes the project labels as the tag_list' do
        get api('/projects', user)

        expect(response.status).to eq 200
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include('tag_list')
      end

      it 'includes open_issues_count' do
        get api('/projects', user)

        expect(response.status).to eq 200
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include('open_issues_count')
      end

      it 'does not include open_issues_count if issues are disabled' do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

        get api('/projects', user)

        expect(response.status).to eq 200
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.find { |hash| hash['id'] == project.id }.keys).not_to include('open_issues_count')
      end

      context 'and with_issues_enabled=true' do
        it 'only returns projects with issues enabled' do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get api('/projects?with_issues_enabled=true', user)

          expect(response.status).to eq 200
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).not_to include(project.id)
        end
      end

      it "does not include statistics by default" do
        get api('/projects', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes statistics if requested" do
        get api('/projects', user), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).to include 'statistics'
      end

      context 'when external issue tracker is enabled' do
        let!(:jira_service) { create(:jira_service, project: project) }

        it 'includes open_issues_count' do
          get api('/projects', user)

          expect(response.status).to eq 200
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first.keys).to include('open_issues_count')
          expect(json_response.find { |hash| hash['id'] == project.id }.keys).to include('open_issues_count')
        end

        it 'does not include open_issues_count if issues are disabled' do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

          get api('/projects', user)

          expect(response.status).to eq 200
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.find { |hash| hash['id'] == project.id }.keys).not_to include('open_issues_count')
        end
      end

      context 'and with simple=true' do
        it 'returns a simplified version of all the projects' do
          expected_keys = %w(
            id description default_branch tag_list
            ssh_url_to_repo http_url_to_repo web_url
            name name_with_namespace
            path path_with_namespace
            star_count forks_count
            created_at last_activity_at
            avatar_url
          )

          get api('/projects?simple=true', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first.keys).to match_array expected_keys
        end
      end

      context 'and using search' do
        it_behaves_like 'projects response' do
          let(:filter) { { search: project.name } }
          let(:current_user) { user }
          let(:projects) { [project] }
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
          get api('/projects', user), { visibility: 'private' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id, project2.id, project3.id)
        end

        it 'filters based on internal visibility param' do
          project2.update_attribute(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)

          get api('/projects', user), { visibility: 'internal' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project2.id)
        end

        it 'filters based on public visibility param' do
          get api('/projects', user), { visibility: 'public' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(public_project.id)
        end
      end

      context 'and using sorting' do
        it 'returns the correct order when sorted by id' do
          get api('/projects', user), { order_by: 'id', sort: 'desc' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['id']).to eq(project3.id)
        end
      end

      context 'and with owned=true' do
        it 'returns an array of projects the user owns' do
          get api('/projects', user4), owned: true

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['name']).to eq(project4.name)
          expect(json_response.first['owner']['username']).to eq(user4.username)
        end
      end

      context 'and with starred=true' do
        let(:public_project) { create(:project, :public) }

        before do
          project_member
          user3.update_attributes(starred_projects: [project, project2, project3, public_project])
        end

        it 'returns the starred projects viewable by the user' do
          get api('/projects', user3), starred: true

          expect(response).to have_gitlab_http_status(200)
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
          user.update_attributes(starred_projects: [project5, project7, project8, project9])
        end

        context 'including owned filter' do
          it 'returns only projects that satisfy all query parameters' do
            get api('/projects', user), { visibility: 'public', owned: true, starred: true, search: 'gitlab' }

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(1)
            expect(json_response.first['id']).to eq(project7.id)
          end
        end

        context 'including membership filter' do
          before do
            create(:project_member,
                   user: user,
                   project: project5,
                   access_level: ProjectMember::MASTER)
          end

          it 'returns only projects that satisfy all query parameters' do
            get api('/projects', user), { visibility: 'public', membership: true, starred: true, search: 'gitlab' }

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(2)
            expect(json_response.map { |project| project['id'] }).to contain_exactly(project5.id, project7.id)
          end
        end
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

          expect(response.status).to eq 200
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
        let(:projects) { Project.all }
      end
    end
  end

  describe 'POST /projects' do
    context 'maximum number of projects reached' do
      it 'does not create new project and respond with 403' do
        allow_any_instance_of(User).to receive(:projects_limit_left).and_return(0)
        expect { post api('/projects', user2), name: 'foo' }
          .to change {Project.count}.by(0)
        expect(response).to have_gitlab_http_status(403)
      end
    end

    it 'creates new project without path but with name and returns 201' do
      expect { post api('/projects', user), name: 'Foo Project' }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project without name but with path and returns 201' do
      expect { post api('/projects', user), path: 'foo_project' }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('foo_project')
      expect(project.path).to eq('foo_project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api('/projects', user), path: 'path-project-Foo', name: 'Foo Project' }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('path-project-Foo')
    end

    it 'creates last project before reaching project limit' do
      allow_any_instance_of(User).to receive(:projects_limit_left).and_return(1)
      post api('/projects', user2), name: 'foo'
      expect(response).to have_gitlab_http_status(201)
    end

    it 'does not create new project without name or path and returns 400' do
      expect { post api('/projects', user) }.not_to change { Project.count }
      expect(response).to have_gitlab_http_status(400)
    end

    it "assigns attributes to project" do
      project = attributes_for(:project, {
        path: 'camelCasePath',
        issues_enabled: false,
        jobs_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false,
        resolve_outdated_diff_discussions: false,
        only_allow_merge_if_pipeline_succeeds: false,
        request_access_enabled: true,
        only_allow_merge_if_all_discussions_are_resolved: false,
        ci_config_path: 'a/custom/path',
        merge_method: 'ff'
      })

      post api('/projects', user), project

      expect(response).to have_gitlab_http_status(201)

      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker issues_enabled merge_requests_enabled wiki_enabled storage_version].include?(k)

        expect(json_response[k.to_s]).to eq(v)
      end

      # Check feature permissions attributes
      project = Project.find_by_path(project[:path])
      expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::DISABLED)
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api('/projects', user), project

      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api('/projects', user), project

      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api('/projects', user), project

      expect(json_response['visibility']).to eq('private')
    end

    it 'sets tag list to a project' do
      project = attributes_for(:project, tag_list: %w[tagFirst tagSecond])

      post api('/projects', user), project

      expect(json_response['tag_list']).to eq(%w[tagFirst tagSecond])
    end

    it 'uploads avatar for project a project' do
      project = attributes_for(:project, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif'))

      post api('/projects', user), project

      project_id = json_response['id']
      expect(json_response['avatar_url']).to eq("http://localhost/uploads/-/system/project/avatar/#{project_id}/banana_sample.gif")
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api('/projects', user), project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve if resolve_outdated_diff_discussions' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api('/projects', user), project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if merge_when_pipeline_succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge if only_allow_merge_if_all_discussions_are_resolved is nil' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: nil)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end

    it 'sets the merge method of a project to rebase merge' do
      project = attributes_for(:project, merge_method: 'rebase_merge')

      post api('/projects', user), project

      expect(json_response['merge_method']).to eq('rebase_merge')
    end

    it 'rejects invalid values for merge_method' do
      project = attributes_for(:project, merge_method: 'totally_not_valid_method')

      post api('/projects', user), project

      expect(response).to have_gitlab_http_status(400)
    end

    it 'ignores import_url when it is nil' do
      project = attributes_for(:project, import_url: nil)

      post api('/projects', user), project

      expect(response).to have_gitlab_http_status(201)
    end

    context 'when a visibility level is restricted' do
      let(:project_param) { attributes_for(:project, visibility: 'public') }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'does not allow a non-admin to use a restricted visibility level' do
        post api('/projects', user), project_param

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['visibility_level'].first).to(
          match('restricted by your GitLab administrator')
        )
      end

      it 'allows an admin to override restricted visibility settings' do
        post api('/projects', admin), project_param

        expect(json_response['visibility']).to eq('public')
      end
    end
  end

  describe 'GET /users/:user_id/projects/' do
    let!(:public_project) { create(:project, :public, name: 'public_project', creator_id: user4.id, namespace: user4.namespace) }

    it 'returns error when user not found' do
      get api('/users/9999/projects/')

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns projects filtered by user' do
      get api("/users/#{user4.id}/projects/", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
    end
  end

  describe 'POST /projects/user/:id' do
    it 'creates new project without path but with name and return 201' do
      expect { post api("/projects/user/#{user.id}", admin), name: 'Foo Project' }.to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.last

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api("/projects/user/#{user.id}", admin), path: 'path-project-Foo', name: 'Foo Project' }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.last

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('path-project-Foo')
    end

    it 'responds with 400 on failure and not project' do
      expect { post api("/projects/user/#{user.id}", admin) }
        .not_to change { Project.count }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'assigns attributes to project' do
      project = attributes_for(:project, {
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false,
        request_access_enabled: true,
        jobs_enabled: true
      })

      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_gitlab_http_status(201)

      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker path storage_version].include?(k)

        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['visibility']).to eq('private')
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if pipeline succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end
  end

  describe "POST /projects/:id/uploads" do
    before do
      project
    end

    it "uploads the file and returns its info" do
      post api("/projects/#{project.id}/uploads", user), file: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['alt']).to eq("dk")
      expect(json_response['url']).to start_with("/uploads/")
      expect(json_response['url']).to end_with("/dk.png")
    end
  end

  describe 'GET /projects/:id' do
    context 'when unauthenticated' do
      it 'returns the public projects' do
        public_project = create(:project, :public)

        get api("/projects/#{public_project.id}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(public_project.id)
        expect(json_response['description']).to eq(public_project.description)
        expect(json_response['default_branch']).to eq(public_project.default_branch)
        expect(json_response.keys).not_to include('permissions')
      end
    end

    context 'when authenticated as an admin' do
      it 'returns a project by id including repository_storage' do
        project
        project_member
        group = create(:group)
        link = create(:project_group_link, project: project, group: group)

        get api("/projects/#{project.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['tag_list']).to be_an Array
        expect(json_response['archived']).to be_falsey
        expect(json_response['visibility']).to be_present
        expect(json_response['ssh_url_to_repo']).to be_present
        expect(json_response['http_url_to_repo']).to be_present
        expect(json_response['web_url']).to be_present
        expect(json_response['owner']).to be_a Hash
        expect(json_response['owner']).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to be_present
        expect(json_response['issues_enabled']).to be_present
        expect(json_response['merge_requests_enabled']).to be_present
        expect(json_response['wiki_enabled']).to be_present
        expect(json_response['jobs_enabled']).to be_present
        expect(json_response['snippets_enabled']).to be_present
        expect(json_response['container_registry_enabled']).to be_present
        expect(json_response['created_at']).to be_present
        expect(json_response['last_activity_at']).to be_present
        expect(json_response['shared_runners_enabled']).to be_present
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
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
        expect(json_response['repository_storage']).to eq(project.repository_storage)
      end
    end

    context 'when authenticated as a regular user' do
      before do
        project
        project_member
      end

      it 'returns a project by id' do
        group = create(:group)
        link = create(:project_group_link, project: project, group: group)

        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['tag_list']).to be_an Array
        expect(json_response['archived']).to be_falsey
        expect(json_response['visibility']).to be_present
        expect(json_response['ssh_url_to_repo']).to be_present
        expect(json_response['http_url_to_repo']).to be_present
        expect(json_response['web_url']).to be_present
        expect(json_response['owner']).to be_a Hash
        expect(json_response['owner']).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to be_present
        expect(json_response['issues_enabled']).to be_present
        expect(json_response['merge_requests_enabled']).to be_present
        expect(json_response['wiki_enabled']).to be_present
        expect(json_response['jobs_enabled']).to be_present
        expect(json_response['snippets_enabled']).to be_present
        expect(json_response['resolve_outdated_diff_discussions']).to eq(project.resolve_outdated_diff_discussions)
        expect(json_response['container_registry_enabled']).to be_present
        expect(json_response['created_at']).to be_present
        expect(json_response['last_activity_at']).to be_present
        expect(json_response['shared_runners_enabled']).to be_present
        expect(json_response['creator_id']).to be_present
        expect(json_response['namespace']).to be_present
        expect(json_response['import_status']).to be_present
        expect(json_response).to include("import_error")
        expect(json_response['avatar_url']).to be_nil
        expect(json_response['star_count']).to be_present
        expect(json_response['forks_count']).to be_present
        expect(json_response['public_jobs']).to be_present
        expect(json_response['ci_config_path']).to be_nil
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['only_allow_merge_if_pipeline_succeeds']).to eq(project.only_allow_merge_if_pipeline_succeeds)
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
        expect(json_response['merge_method']).to eq(project.merge_method.to_s)
        expect(json_response).not_to have_key('repository_storage')
      end

      it 'returns a project by path name' do
        get api("/projects/#{project.id}", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(project.name)
      end

      it 'returns a 404 error if not found' do
        get api('/projects/42', user)
        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)
        get api("/projects/#{project.id}", other_user)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'handles users with dots' do
        dot_user = create(:user, username: 'dot.user')
        project = create(:project, creator_id: dot_user.id, namespace: dot_user.namespace)

        get api("/projects/#{CGI.escape(project.full_path)}", dot_user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(project.name)
      end

      it 'exposes namespace fields' do
        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['namespace']).to eq({
          'id' => user.namespace.id,
          'name' => user.namespace.name,
          'path' => user.namespace.path,
          'kind' => user.namespace.kind,
          'full_path' => user.namespace.full_path,
          'parent_id' => nil
        })
      end

      it "does not include statistics by default" do
        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include 'statistics'
      end

      it "includes statistics if requested" do
        get api("/projects/#{project.id}", user), statistics: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include 'statistics'
      end

      it "includes import_error if user can admin project" do
        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include("import_error")
      end

      it "does not include import_error if user cannot admin project" do
        get api("/projects/#{project.id}", user3)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include("import_error")
      end

      context 'links exposure' do
        it 'exposes related resources full URIs' do
          get api("/projects/#{project.id}", user)

          links = json_response['_links']

          expect(links['self']).to end_with("/api/v4/projects/#{project.id}")
          expect(links['issues']).to end_with("/api/v4/projects/#{project.id}/issues")
          expect(links['merge_requests']).to end_with("/api/v4/projects/#{project.id}/merge_requests")
          expect(links['repo_branches']).to end_with("/api/v4/projects/#{project.id}/repository/branches")
          expect(links['labels']).to end_with("/api/v4/projects/#{project.id}/labels")
          expect(links['events']).to end_with("/api/v4/projects/#{project.id}/events")
          expect(links['members']).to end_with("/api/v4/projects/#{project.id}/members")
        end

        it 'filters related URIs when their feature is not enabled' do
          project = create(:project, :public,
                           :merge_requests_disabled,
                           :issues_disabled,
                           creator_id: user.id,
                           namespace: user.namespace)

          get api("/projects/#{project.id}", user)

          links = json_response['_links']

          expect(links.has_key?('merge_requests')).to be_falsy
          expect(links.has_key?('issues')).to be_falsy
          expect(links['self']).to end_with("/api/v4/projects/#{project.id}")
        end
      end

      describe 'permissions' do
        context 'all projects' do
          before do
            project.add_master(user)
          end

          it 'contains permission information' do
            get api("/projects", user)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response.first['permissions']['project_access']['access_level'])
            .to eq(Gitlab::Access::MASTER)
            expect(json_response.first['permissions']['group_access']).to be_nil
          end
        end

        context 'personal project' do
          it 'sets project access and returns 200' do
            project.add_master(user)
            get api("/projects/#{project.id}", user)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['permissions']['project_access']['access_level'])
            .to eq(Gitlab::Access::MASTER)
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

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['permissions']['project_access']).to be_nil
            expect(json_response['permissions']['group_access']['access_level'])
            .to eq(Gitlab::Access::OWNER)
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/users' do
    shared_examples_for 'project users response' do
      it 'returns the project users' do
        get api("/projects/#{project.id}/users", current_user)

        user = project.namespace.owner

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)

        first_user = json_response.first
        expect(first_user['username']).to eq(user.username)
        expect(first_user['name']).to eq(user.name)
        expect(first_user.keys).to contain_exactly(*%w[name username id state avatar_url web_url])
      end
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
          let(:current_user) { user }
        end
      end

      it 'returns a 404 error if not found' do
        get api('/projects/42/users', user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)

        get api("/projects/#{project.id}/users", other_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/snippets' do
    before do
      snippet
    end

    it 'returns an array of project snippets' do
      get api("/projects/#{project.id}/snippets", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(snippet.title)
    end
  end

  describe 'GET /projects/:id/snippets/:snippet_id' do
    it 'returns a project snippet' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(snippet.title)
    end

    it 'returns a 404 error if snippet id not found' do
      get api("/projects/#{project.id}/snippets/1234", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'POST /projects/:id/snippets' do
    it 'creates a new project snippet' do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb', code: 'test', visibility: 'private'
      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('api test')
    end

    it 'returns a 400 error if invalid snippet is given' do
      post api("/projects/#{project.id}/snippets", user)
      expect(status).to eq(400)
    end
  end

  describe 'PUT /projects/:id/snippets/:snippet_id' do
    it 'updates an existing project snippet' do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        code: 'updated code'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('example')
      expect(snippet.reload.content).to eq('updated code')
    end

    it 'updates an existing project snippet with new title' do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        title: 'other api test'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('other api test')
    end
  end

  describe 'DELETE /projects/:id/snippets/:snippet_id' do
    before do
      snippet
    end

    it 'deletes existing project snippet' do
      expect do
        delete api("/projects/#{project.id}/snippets/#{snippet.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { Snippet.count }.by(-1)
    end

    it 'returns 404 when deleting unknown snippet id' do
      delete api("/projects/#{project.id}/snippets/1234", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/snippets/#{snippet.id}", user) }
    end
  end

  describe 'GET /projects/:id/snippets/:snippet_id/raw' do
    it 'gets a raw project snippet' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/raw", user)
      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns a 404 error if raw project snippet not found' do
      get api("/projects/#{project.id}/snippets/5555/raw", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'fork management' do
    let(:project_fork_target) { create(:project) }
    let(:project_fork_source) { create(:project, :public) }

    describe 'POST /projects/:id/fork/:forked_from_id' do
      let(:new_project_fork_source) { create(:project, :public) }

      it "is not available for non admin users" do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", user)
        expect(response).to have_gitlab_http_status(403)
      end

      it 'allows project to be forked from an existing project' do
        expect(project_fork_target.forked?).not_to be_truthy
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        expect(response).to have_gitlab_http_status(201)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked_project_link).not_to be_nil
        expect(project_fork_target.forked?).to be_truthy
      end

      it 'refreshes the forks count cachce' do
        expect(project_fork_source.forks_count).to be_zero

        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)

        expect(project_fork_source.forks_count).to eq(1)
      end

      it 'fails if forked_from project which does not exist' do
        post api("/projects/#{project_fork_target.id}/fork/9999", admin)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'fails with 409 if already forked' do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        post api("/projects/#{project_fork_target.id}/fork/#{new_project_fork_source.id}", admin)
        expect(response).to have_gitlab_http_status(409)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked?).to be_truthy
      end
    end

    describe 'DELETE /projects/:id/fork' do
      it "is not visible to users outside group" do
        delete api("/projects/#{project_fork_target.id}/fork", user)
        expect(response).to have_gitlab_http_status(404)
      end

      context 'when users belong to project group' do
        let(:project_fork_target) { create(:project, group: create(:group)) }

        before do
          project_fork_target.group.add_owner user
          project_fork_target.group.add_developer user2
        end

        context 'for a forked project' do
          before do
            post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
            project_fork_target.reload
            expect(project_fork_target.forked_from_project).not_to be_nil
            expect(project_fork_target.forked?).to be_truthy
          end

          it 'makes forked project unforked' do
            delete api("/projects/#{project_fork_target.id}/fork", admin)

            expect(response).to have_gitlab_http_status(204)
            project_fork_target.reload
            expect(project_fork_target.forked_from_project).to be_nil
            expect(project_fork_target.forked?).not_to be_truthy
          end

          it_behaves_like '412 response' do
            let(:request) { api("/projects/#{project_fork_target.id}/fork", admin) }
          end
        end

        it 'is forbidden to non-owner users' do
          delete api("/projects/#{project_fork_target.id}/fork", user2)
          expect(response).to have_gitlab_http_status(403)
        end

        it 'is idempotent if not forked' do
          expect(project_fork_target.forked_from_project).to be_nil
          delete api("/projects/#{project_fork_target.id}/fork", admin)
          expect(response).to have_gitlab_http_status(304)
          expect(project_fork_target.reload.forked_from_project).to be_nil
        end
      end
    end

    describe 'GET /projects/:id/forks' do
      let(:private_fork) { create(:project, :private, :empty_repo) }
      let(:member) { create(:user) }
      let(:non_member) { create(:user) }

      before do
        private_fork.add_developer(member)
      end

      context 'for a forked project' do
        before do
          post api("/projects/#{private_fork.id}/fork/#{project_fork_source.id}", admin)
          private_fork.reload
          expect(private_fork.forked_from_project).not_to be_nil
          expect(private_fork.forked?).to be_truthy
          project_fork_source.reload
          expect(project_fork_source.forks.length).to eq(1)
          expect(project_fork_source.forks).to include(private_fork)
        end

        context 'for a user that can access the forks' do
          it 'returns the forks' do
            get api("/projects/#{project_fork_source.id}/forks", member)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(1)
            expect(json_response[0]['name']).to eq(private_fork.name)
          end
        end

        context 'for a user that cannot access the forks' do
          it 'returns an empty array' do
            get api("/projects/#{project_fork_source.id}/forks", non_member)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(0)
          end
        end
      end

      context 'for a non-forked project' do
        it 'returns an empty array' do
          get api("/projects/#{project_fork_source.id}/forks")

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response.length).to eq(0)
        end
      end
    end
  end

  describe "POST /projects/:id/share" do
    let(:group) { create(:group) }

    it "shares project with group" do
      expires_at = 10.days.from_now.to_date

      expect do
        post api("/projects/#{project.id}/share", user), group_id: group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at
      end.to change { ProjectGroupLink.count }.by(1)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['group_id']).to eq(group.id)
      expect(json_response['group_access']).to eq(Gitlab::Access::DEVELOPER)
      expect(json_response['expires_at']).to eq(expires_at.to_s)
    end

    it "returns a 400 error when group id is not given" do
      post api("/projects/#{project.id}/share", user), group_access: Gitlab::Access::DEVELOPER
      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 error when access level is not given" do
      post api("/projects/#{project.id}/share", user), group_id: group.id
      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 error when sharing is disabled" do
      project.namespace.update(share_with_group_lock: true)
      post api("/projects/#{project.id}/share", user), group_id: group.id, group_access: Gitlab::Access::DEVELOPER
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns a 404 error when user cannot read group' do
      private_group = create(:group, :private)

      post api("/projects/#{project.id}/share", user), group_id: private_group.id, group_access: Gitlab::Access::DEVELOPER

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 error when group does not exist' do
      post api("/projects/#{project.id}/share", user), group_id: 1234, group_access: Gitlab::Access::DEVELOPER

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns a 400 error when wrong params passed" do
      post api("/projects/#{project.id}/share", user), group_id: group.id, group_access: 1234

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq 'group_access does not have a valid value'
    end
  end

  describe 'DELETE /projects/:id/share/:group_id' do
    context 'for a valid group' do
      let(:group) { create(:group, :public) }

      before do
        create(:project_group_link, group: group, project: project)
      end

      it 'returns 204 when deleting a group share' do
        delete api("/projects/#{project.id}/share/#{group.id}", user)

        expect(response).to have_gitlab_http_status(204)
        expect(project.project_group_links).to be_empty
      end

      it 'returns 204 when deleting a group share' do
        delete api("/projects/#{project.id}/share/#{group.id}", user)

        expect(response).to have_gitlab_http_status(204)
        expect(project.project_group_links).to be_empty
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/share/#{group.id}", user) }
      end
    end

    it 'returns a 400 when group id is not an integer' do
      delete api("/projects/#{project.id}/share/foo", user)

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns a 404 error when group link does not exist' do
      delete api("/projects/#{project.id}/share/1234", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 error when project does not exist' do
      delete api("/projects/123/share/1234", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'PUT /projects/:id' do
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

    it 'returns 400 when nothing sent' do
      project_param = {}

      put api("/projects/#{project.id}", user), project_param

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to match('at least one parameter must be provided')
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        project_param = { name: 'bar' }

        put api("/projects/#{project.id}"), project_param

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated as project owner' do
      it 'updates name' do
        project_param = { name: 'bar' }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level' do
        project_param = { visibility: 'public' }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level from public to private' do
        project3.update_attributes({ visibility_level: Gitlab::VisibilityLevel::PUBLIC })
        project_param = { visibility: 'private' }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end

        expect(json_response['visibility']).to eq('private')
      end

      it 'does not update name to existing name' do
        project_param = { name: project3.name }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['name']).to eq(['has already been taken'])
      end

      it 'updates request_access_enabled' do
        project_param = { request_access_enabled: false }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['request_access_enabled']).to eq(false)
      end

      it 'updates approvals_before_merge' do
        project_param = { approvals_before_merge: 3 }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approvals_before_merge']).to eq(3)
      end

      it 'updates path & name to existing path & name in different namespace' do
        project_param = { path: project4.path, name: project4.name }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates jobs_enabled' do
        project_param = { jobs_enabled: true }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates merge_method' do
        project_param = { merge_method: 'ff' }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'rejects to update merge_method when merge_method is invalid' do
        project_param = { merge_method: 'invalid' }

        put api("/projects/#{project3.id}", user), project_param

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when authenticated as project master' do
      it 'updates path' do
        project_param = { path: 'bar' }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_gitlab_http_status(200)
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
                          description: 'new description' }

        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_gitlab_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'does not update path to existing path' do
        project_param = { path: project.path }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'does not update name' do
        project_param = { name: 'bar' }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not update visibility_level' do
        project_param = { visibility: 'public' }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_gitlab_http_status(403)
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
        put api("/projects/#{project.id}", user3), project_param
        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/archive' do
    context 'on an unarchived project' do
      it 'archives the project' do
        post api("/projects/#{project.id}/archive", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'on an archived project' do
      before do
        project.archive!
      end

      it 'remains archived' do
        post api("/projects/#{project.id}/archive", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.add_developer(user3)
      end

      it 'rejects the action' do
        post api("/projects/#{project.id}/archive", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/unarchive' do
    context 'on an unarchived project' do
      it 'remains unarchived' do
        post api("/projects/#{project.id}/unarchive", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'on an archived project' do
      before do
        project.archive!
      end

      it 'unarchives the project' do
        post api("/projects/#{project.id}/unarchive", user)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.add_developer(user3)
      end

      it 'rejects the action' do
        post api("/projects/#{project.id}/unarchive", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/star' do
    context 'on an unstarred project' do
      it 'stars the project' do
        expect { post api("/projects/#{project.id}/star", user) }.to change { project.reload.star_count }.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['star_count']).to eq(1)
      end
    end

    context 'on a starred project' do
      before do
        user.toggle_star(project)
        project.reload
      end

      it 'does not modify the star count' do
        expect { post api("/projects/#{project.id}/star", user) }.not_to change { project.reload.star_count }

        expect(response).to have_gitlab_http_status(304)
      end
    end
  end

  describe 'POST /projects/:id/unstar' do
    context 'on a starred project' do
      before do
        user.toggle_star(project)
        project.reload
      end

      it 'unstars the project' do
        expect { post api("/projects/#{project.id}/unstar", user) }.to change { project.reload.star_count }.by(-1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['star_count']).to eq(0)
      end
    end

    context 'on an unstarred project' do
      it 'does not modify the star count' do
        expect { post api("/projects/#{project.id}/unstar", user) }.not_to change { project.reload.star_count }

        expect(response).to have_gitlab_http_status(304)
      end
    end
  end

  describe 'GET /projects/:id/languages' do
    context 'with an authorized user' do
      it_behaves_like 'languages and percentages JSON response' do
        let(:project) { project3 }
      end

      it 'returns not_found(404) for not existing project' do
        get api("/projects/9999999999/languages", user)

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
    context 'when authenticated as user' do
      it 'removes project' do
        delete api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(202)
        expect(json_response['message']).to eql('202 Accepted')
      end

      it_behaves_like '412 response' do
        let(:success_status) { 202 }
        let(:request) { api("/projects/#{project.id}", user) }
      end

      it 'does not remove a project if not an owner' do
        user3 = create(:user)
        project.add_developer(user3)
        delete api("/projects/#{project.id}", user3)
        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not remove a non existing project' do
        delete api('/projects/1328', user)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not remove a project not attached to user' do
        delete api("/projects/#{project.id}", user2)
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when authenticated as admin' do
      it 'removes any existing project' do
        delete api("/projects/#{project.id}", admin)

        expect(response).to have_gitlab_http_status(202)
        expect(json_response['message']).to eql('202 Accepted')
      end

      it 'does not remove a non existing project' do
        delete api('/projects/1328', admin)
        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:success_status) { 202 }
        let(:request) { api("/projects/#{project.id}", admin) }
      end
    end
  end

  describe 'POST /projects/:id/fork' do
    let(:project) do
      create(:project, :repository, creator: user, namespace: user.namespace)
    end
    let(:group) { create(:group) }
    let(:group2) do
      group = create(:group, name: 'group2_name')
      group.add_owner(user2)
      group
    end

    let(:group3) do
      group = create(:group, name: 'group3_name', parent: group2)
      group.add_owner(user2)
      group
    end

    before do
      project.add_reporter(user2)
    end

    context 'when authenticated' do
      it 'forks if user has sufficient access to project' do
        post api("/projects/#{project.id}/fork", user2)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'forks if user is admin' do
        post api("/projects/#{project.id}/fork", admin)

        expect(response).to have_gitlab_http_status(201)
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
        post api("/projects/#{project.id}/fork", new_user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'fails if forked project exists in the user namespace' do
        post api("/projects/#{project.id}/fork", user)

        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']['name']).to eq(['has already been taken'])
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'fails if project to fork from does not exist' do
        post api('/projects/424242/fork', user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'forks with explicit own user namespace id' do
        post api("/projects/#{project.id}/fork", user2), namespace: user2.namespace.id

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks with explicit own user name as namespace' do
        post api("/projects/#{project.id}/fork", user2), namespace: user2.username

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks to another user when admin' do
        post api("/projects/#{project.id}/fork", admin), namespace: user2.username

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'fails if trying to fork to another user when not admin' do
        post api("/projects/#{project.id}/fork", user2), namespace: admin.namespace.id

        expect(response).to have_gitlab_http_status(404)
      end

      it 'fails if trying to fork to non-existent namespace' do
        post api("/projects/#{project.id}/fork", user2), namespace: 42424242

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Target Namespace Not Found')
      end

      it 'forks to owned group' do
        post api("/projects/#{project.id}/fork", user2), namespace: group2.name

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group2.name)
      end

      it 'forks to owned subgroup' do
        full_path = "#{group2.path}/#{group3.path}"
        post api("/projects/#{project.id}/fork", user2), namespace: full_path

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group3.name)
        expect(json_response['namespace']['full_path']).to eq(full_path)
      end

      it 'fails to fork to not owned group' do
        post api("/projects/#{project.id}/fork", user2), namespace: group.name

        expect(response).to have_gitlab_http_status(404)
      end

      it 'forks to not owned group when admin' do
        post api("/projects/#{project.id}/fork", admin), namespace: group.name

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group.name)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/projects/#{project.id}/fork")

        expect(response).to have_gitlab_http_status(401)
        expect(json_response['message']).to eq('401 Unauthorized')
      end
    end
  end

  describe 'POST /projects/:id/housekeeping' do
    let(:housekeeping) { Projects::HousekeepingService.new(project) }

    before do
      allow(Projects::HousekeepingService).to receive(:new).with(project).and_return(housekeeping)
    end

    context 'when authenticated as owner' do
      it 'starts the housekeeping process' do
        expect(housekeeping).to receive(:execute).once

        post api("/projects/#{project.id}/housekeeping", user)

        expect(response).to have_gitlab_http_status(201)
      end

      context 'when housekeeping lease is taken' do
        it 'returns conflict' do
          expect(housekeeping).to receive(:execute).once.and_raise(Projects::HousekeepingService::LeaseTaken)

          post api("/projects/#{project.id}/housekeeping", user)

          expect(response).to have_gitlab_http_status(409)
          expect(json_response['message']).to match(/Somebody already triggered housekeeping for this project/)
        end
      end
    end

    context 'when authenticated as developer' do
      before do
        project_member
      end

      it 'returns forbidden error' do
        post api("/projects/#{project.id}/housekeeping", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/projects/#{project.id}/housekeeping")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  it_behaves_like 'custom attributes endpoints', 'projects' do
    let(:attributable) { project }
    let(:other_attributable) { project2 }
  end
end
