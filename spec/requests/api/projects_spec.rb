# frozen_string_literal: true

require 'spec_helper'

shared_examples 'languages and percentages JSON response' do
  let(:expected_languages) { project.repository.languages.map { |language| language.values_at(:label, :value)}.to_h }

  before do
    allow(DetectRepositoryLanguagesWorker).to receive(:perform_async).and_call_original

    allow(project.repository).to receive(:languages).and_return(
      [{ value: 66.69, label: "Ruby", color: "#701516", highlight: "#701516" },
       { value: 22.98, label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a" },
       { value: 7.91, label: "HTML", color: "#e34c26", highlight: "#e34c26" },
       { value: 2.42, label: "CoffeeScript", color: "#244776", highlight: "#244776" }]
    )
  end

  context "when the languages haven't been detected yet" do
    it 'returns expected language values', :sidekiq_might_not_need_inline do
      get api("/projects/#{project.id}/languages", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({})

      get api("/projects/#{project.id}/languages", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(expected_languages)
    end
  end

  context 'when the languages were detected before' do
    before do
      Projects::DetectRepositoryLanguagesService.new(project, project.owner).execute
    end

    it 'returns the detection from the database' do
      # Allow this to happen once, so the expected languages can be determined
      expect(project.repository).to receive(:languages).once

      get api("/projects/#{project.id}/languages", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(expected_languages)
      expect(json_response.count).to be > 1
    end
  end
end

describe API::Projects do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:project2) { create(:project, namespace: user.namespace) }
  let(:project_member) { create(:project_member, :developer, user: user3, project: project) }
  let(:user4) { create(:user, username: 'user.with.dot') }
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
    access_level: ProjectMember::MAINTAINER)
  end
  let(:project4) do
    create(:project,
    name: 'third_project',
    path: 'third_project',
    creator_id: user4.id,
    namespace: user4.namespace)
  end

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

  describe 'GET /projects' do
    shared_examples_for 'projects response' do
      it 'returns an array of projects' do
        get api('/projects', current_user), params: filter

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(*projects.map(&:id))
      end

      it 'returns the proper security headers' do
        get api('/projects', current_user), params: filter

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

      it 'does not include projects marked for deletion' do
        project.update(pending_delete: true)

        get api('/projects', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).not_to include(project.id)
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
        get api('/projects', user), params: { statistics: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).to include 'statistics'
      end

      it "does not include license by default" do
        get api('/projects', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('license', 'license_url')
      end

      it "does not include license if requested" do
        get api('/projects', user), params: { license: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('license', 'license_url')
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
            ssh_url_to_repo http_url_to_repo web_url readme_url
            name name_with_namespace
            path path_with_namespace
            star_count forks_count
            created_at last_activity_at
            avatar_url namespace
          )

          get api('/projects?simple=true', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first.keys).to match_array expected_keys
        end
      end

      context 'and using archived' do
        let!(:archived_project) { create(:project, creator_id: user.id, namespace: user.namespace, archived: true) }

        it 'returns archived projects' do
          get api('/projects?archived=true', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user).where(archived: true).size)
          expect(json_response.map { |project| project['id'] }).to include(archived_project.id)
        end

        it 'returns non-archived projects' do
          get api('/projects?archived=false', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(Project.public_or_visible_to_user(user).where(archived: false).size)
          expect(json_response.map { |project| project['id'] }).not_to include(archived_project.id)
        end

        it 'returns every project' do
          get api('/projects', user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(*Project.public_or_visible_to_user(user).pluck(:id))
        end
      end

      context 'and using search' do
        it_behaves_like 'projects response' do
          let(:filter) { { search: project.name } }
          let(:current_user) { user }
          let(:projects) { [project] }
        end
      end

      context 'and using id_after' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_after: project2.id } }
          let(:current_user) { user }
          let(:projects) { [public_project, project, project2, project3].select { |p| p.id > project2.id } }
        end
      end

      context 'and using id_before' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_before: project2.id } }
          let(:current_user) { user }
          let(:projects) { [public_project, project, project2, project3].select { |p| p.id < project2.id } }
        end
      end

      context 'and using both id_after and id_before' do
        it_behaves_like 'projects response' do
          let(:filter) { { id_before: project2.id, id_after: public_project.id } }
          let(:current_user) { user }
          let(:projects) { [public_project, project, project2, project3].select { |p| p.id < project2.id && p.id > public_project.id } }
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
          get api('/projects', user), params: { visibility: 'private' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id, project2.id, project3.id)
        end

        it 'filters based on internal visibility param' do
          project2.update_attribute(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)

          get api('/projects', user), params: { visibility: 'internal' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project2.id)
        end

        it 'filters based on public visibility param' do
          get api('/projects', user), params: { visibility: 'public' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(public_project.id)
        end
      end

      context 'and using the programming language filter' do
        include_context 'with language detection'

        it 'filters case-insensitively by programming language' do
          get api('/projects', user), params: { with_programming_language: 'javascript' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project3.id)
        end
      end

      context 'and using sorting' do
        it 'returns the correct order when sorted by id' do
          get api('/projects', user), params: { order_by: 'id', sort: 'desc' }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['id']).to eq(project3.id)
        end
      end

      context 'and with owned=true' do
        it 'returns an array of projects the user owns' do
          get api('/projects', user4), params: { owned: true }

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
          user3.update(starred_projects: [project, project2, project3, public_project])
        end

        it 'returns the starred projects viewable by the user' do
          get api('/projects', user3), params: { starred: true }

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
          user.update(starred_projects: [project5, project7, project8, project9])
        end

        context 'including owned filter' do
          it 'returns only projects that satisfy all query parameters' do
            get api('/projects', user), params: { visibility: 'public', owned: true, starred: true, search: 'gitlab' }

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
                   access_level: ProjectMember::MAINTAINER)
          end

          it 'returns only projects that satisfy all query parameters' do
            get api('/projects', user), params: { visibility: 'public', membership: true, starred: true, search: 'gitlab' }

            expect(response).to have_gitlab_http_status(200)
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
          get api('/projects', user2), params: { min_access_level: 30 }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(project2.id, project3.id)
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
        expect { post api('/projects', user2), params: { name: 'foo' } }
          .to change {Project.count}.by(0)
        expect(response).to have_gitlab_http_status(403)
      end
    end

    it 'creates new project without path but with name and returns 201' do
      expect { post api('/projects', user), params: { name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project without name but with path and returns 201' do
      expect { post api('/projects', user), params: { path: 'foo_project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('foo_project')
      expect(project.path).to eq('foo_project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api('/projects', user), params: { path: 'path-project-Foo', name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.first

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('path-project-Foo')
    end

    it 'creates last project before reaching project limit' do
      allow_any_instance_of(User).to receive(:projects_limit_left).and_return(1)
      post api('/projects', user2), params: { name: 'foo' }
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
        remove_source_branch_after_merge: true,
        autoclose_referenced_issues: true,
        only_allow_merge_if_pipeline_succeeds: false,
        request_access_enabled: true,
        only_allow_merge_if_all_discussions_are_resolved: false,
        ci_config_path: 'a/custom/path',
        merge_method: 'ff'
      })

      post api('/projects', user), params: project

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

    it 'creates a project using a template' do
      expect { post api('/projects', user), params: { template_name: 'rails', name: 'rails-test' } }
        .to change { Project.count }.by(1)

      expect(response).to have_gitlab_http_status(201)

      project = Project.find(json_response['id'])
      expect(project).to be_saved
      expect(project.import_type).to eq('gitlab_project')
    end

    it 'returns 400 for an invalid template' do
      expect { post api('/projects', user), params: { template_name: 'unknown', name: 'rails-test' } }
        .not_to change { Project.count }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['template_name']).to eq(["'unknown' is unknown or invalid"])
    end

    it 'disallows creating a project with an import_url and template' do
      project_params = { import_url: 'http://example.com', template_name: 'rails', name: 'rails-test' }
      expect { post api('/projects', user), params: project_params }
        .not_to change {  Project.count }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api('/projects', user), params: project

      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api('/projects', user), params: project

      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api('/projects', user), params: project

      expect(json_response['visibility']).to eq('private')
    end

    it 'creates a new project initialized with a README.md' do
      project = attributes_for(:project, initialize_with_readme: 1, name: 'somewhere')

      post api('/projects', user), params: project

      expect(json_response['readme_url']).to eql("#{Gitlab.config.gitlab.url}/#{json_response['namespace']['full_path']}/somewhere/blob/master/README.md")
    end

    it 'sets tag list to a project' do
      project = attributes_for(:project, tag_list: %w[tagFirst tagSecond])

      post api('/projects', user), params: project

      expect(json_response['tag_list']).to eq(%w[tagFirst tagSecond])
    end

    it 'uploads avatar for project a project' do
      project = attributes_for(:project, avatar: fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif'))

      post api('/projects', user), params: project

      project_id = json_response['id']
      expect(json_response['avatar_url']).to eq("http://localhost/uploads/-/system/project/avatar/#{project_id}/banana_sample.gif")
    end

    it 'sets a project as not allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api('/projects', user), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api('/projects', user), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as not removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: false)

      post api('/projects', user), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_falsey
    end

    it 'sets a project as removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: true)

      post api('/projects', user), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)

      post api('/projects', user), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if merge_when_pipeline_succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)

      post api('/projects', user), params: project

      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api('/projects', user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge if only_allow_merge_if_all_discussions_are_resolved is nil' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: nil)

      post api('/projects', user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api('/projects', user), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end

    it 'sets a project as enabling auto close referenced issues' do
      project = attributes_for(:project, autoclose_referenced_issues: true)

      post api('/projects', user), params: project

      expect(json_response['autoclose_referenced_issues']).to be_truthy
    end

    it 'sets a project as disabling auto close referenced issues' do
      project = attributes_for(:project, autoclose_referenced_issues: false)

      post api('/projects', user), params: project

      expect(json_response['autoclose_referenced_issues']).to be_falsey
    end

    it 'sets the merge method of a project to rebase merge' do
      project = attributes_for(:project, merge_method: 'rebase_merge')

      post api('/projects', user), params: project

      expect(json_response['merge_method']).to eq('rebase_merge')
    end

    it 'rejects invalid values for merge_method' do
      project = attributes_for(:project, merge_method: 'totally_not_valid_method')

      post api('/projects', user), params: project

      expect(response).to have_gitlab_http_status(400)
    end

    it 'ignores import_url when it is nil' do
      project = attributes_for(:project, import_url: nil)

      post api('/projects', user), params: project

      expect(response).to have_gitlab_http_status(201)
    end

    context 'when a visibility level is restricted' do
      let(:project_param) { attributes_for(:project, visibility: 'public') }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'does not allow a non-admin to use a restricted visibility level' do
        post api('/projects', user), params: project_param

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['visibility_level'].first).to(
          match('restricted by your GitLab administrator')
        )
      end

      it 'allows an admin to override restricted visibility settings' do
        post api('/projects', admin), params: project_param

        expect(json_response['visibility']).to eq('public')
      end
    end
  end

  describe 'GET /users/:user_id/projects/' do
    let!(:public_project) { create(:project, :public, name: 'public_project', creator_id: user4.id, namespace: user4.namespace) }

    it 'returns error when user not found' do
      get api('/users/0/projects/')

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns projects filtered by user id' do
      get api("/users/#{user4.id}/projects/", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
    end

    context 'and using id_after' do
      let!(:another_public_project) { create(:project, :public, name: 'another_public_project', creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id_after filter given' do
        get api("/users/#{user4.id}/projects?id_after=#{public_project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(another_public_project.id)
      end

      it 'returns both projects without a id_after filter' do
        get api("/users/#{user4.id}/projects", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id, another_public_project.id)
      end
    end

    context 'and using id_before' do
      let!(:another_public_project) { create(:project, :public, name: 'another_public_project', creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id_before filter given' do
        get api("/users/#{user4.id}/projects?id_before=#{another_public_project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id)
      end

      it 'returns both projects without a id_before filter' do
        get api("/users/#{user4.id}/projects", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(public_project.id, another_public_project.id)
      end
    end

    context 'and using both id_before and id_after' do
      let!(:more_projects) { create_list(:project, 5, :public, creator_id: user4.id, namespace: user4.namespace) }

      it 'only returns projects with id matching the range' do
        get api("/users/#{user4.id}/projects?id_after=#{more_projects.first.id}&id_before=#{more_projects.last.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |project| project['id'] }).to contain_exactly(*more_projects[1..-2].map(&:id))
      end
    end

    it 'returns projects filtered by username' do
      get api("/users/#{user4.username}/projects/", user)

      expect(response).to have_gitlab_http_status(200)
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

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(private_project1.id)
    end

    context 'and using the programming language filter' do
      include_context 'with language detection'

      it 'filters case-insensitively by programming language' do
        get api('/projects', user), params: { with_programming_language: 'ruby' }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id)
      end
    end
  end

  describe 'GET /users/:user_id/starred_projects/' do
    before do
      user3.update(starred_projects: [project, project2, project3])
    end

    it 'returns error when user not found' do
      get api('/users/9999/starred_projects/')

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns projects filtered by user' do
      get api("/users/#{user3.id}/starred_projects/", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |project| project['id'] }).to contain_exactly(project.id, project2.id, project3.id)
    end
  end

  describe 'POST /projects/user/:id' do
    it 'creates new project without path but with name and return 201' do
      expect { post api("/projects/user/#{user.id}", admin), params: { name: 'Foo Project' } }.to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.find(json_response['id'])

      expect(project.name).to eq('Foo Project')
      expect(project.path).to eq('foo-project')
    end

    it 'creates new project with name and path and returns 201' do
      expect { post api("/projects/user/#{user.id}", admin), params: { path: 'path-project-Foo', name: 'Foo Project' } }
        .to change { Project.count }.by(1)
      expect(response).to have_gitlab_http_status(201)

      project = Project.find(json_response['id'])

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

      post api("/projects/user/#{user.id}", admin), params: project

      expect(response).to have_gitlab_http_status(201)

      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker path storage_version].include?(k)

        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it 'sets a project as public' do
      project = attributes_for(:project, visibility: 'public')

      post api("/projects/user/#{user.id}", admin), params: project

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['visibility']).to eq('public')
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, visibility: 'internal')

      post api("/projects/user/#{user.id}", admin), params: project

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['visibility']).to eq('internal')
    end

    it 'sets a project as private' do
      project = attributes_for(:project, visibility: 'private')

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['visibility']).to eq('private')
    end

    it 'sets a project as not allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: false)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_falsey
    end

    it 'sets a project as allowing outdated diff discussions to automatically resolve' do
      project = attributes_for(:project, resolve_outdated_diff_discussions: true)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['resolve_outdated_diff_discussions']).to be_truthy
    end

    it 'sets a project as not removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: false)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_falsey
    end

    it 'sets a project as removing source branches' do
      project = attributes_for(:project, remove_source_branch_after_merge: true)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['remove_source_branch_after_merge']).to be_truthy
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: false)
      post api("/projects/user/#{user.id}", admin), params: project
      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if pipeline succeeds' do
      project = attributes_for(:project, only_allow_merge_if_pipeline_succeeds: true)
      post api("/projects/user/#{user.id}", admin), params: project
      expect(json_response['only_allow_merge_if_pipeline_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: false)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: true)

      post api("/projects/user/#{user.id}", admin), params: project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end
  end

  describe "POST /projects/:id/uploads" do
    before do
      project
    end

    it "uploads the file and returns its info" do
      post api("/projects/#{project.id}/uploads", user), params: { file: fixture_file_upload("spec/fixtures/dk.png", "image/png") }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['alt']).to eq("dk")
      expect(json_response['url']).to start_with("/uploads/")
      expect(json_response['url']).to end_with("/dk.png")
    end
  end

  describe 'GET /projects/:id' do
    context 'when unauthenticated' do
      it 'does not return private projects' do
        private_project = create(:project, :private)

        get api("/projects/#{private_project.id}")

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns public projects' do
        public_project = create(:project, :repository, :public)

        get api("/projects/#{public_project.id}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(public_project.id)
        expect(json_response['description']).to eq(public_project.description)
        expect(json_response['default_branch']).to eq(public_project.default_branch)
        expect(json_response['ci_config_path']).to eq(public_project.ci_config_path)
        expect(json_response.keys).not_to include('permissions')
      end

      context 'the project is a public fork' do
        it 'hides details of a public fork parent' do
          public_project = create(:project, :repository, :public)
          fork = fork_project(public_project)

          get api("/projects/#{fork.id}")

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['forked_from_project']).to be_nil
        end
      end

      context 'and the project has a private repository' do
        let(:project) { create(:project, :repository, :public, :repository_private) }
        let(:protected_attributes) { %w(default_branch ci_config_path) }

        it 'hides protected attributes of private repositories if user is not a member' do
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(200)
          protected_attributes.each do |attribute|
            expect(json_response.keys).not_to include(attribute)
          end
        end

        it 'exposes protected attributes of private repositories if user is a member' do
          project.add_developer(user)

          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(200)
          protected_attributes.each do |attribute|
            expect(json_response.keys).to include(attribute)
          end
        end
      end
    end

    context 'when authenticated as an admin' do
      it 'returns a project by id' do
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
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to be_present
        expect(json_response['issues_enabled']).to be_present
        expect(json_response['merge_requests_enabled']).to be_present
        expect(json_response['wiki_enabled']).to be_present
        expect(json_response['jobs_enabled']).to be_present
        expect(json_response['snippets_enabled']).to be_present
        expect(json_response['snippets_access_level']).to be_present
        expect(json_response['repository_access_level']).to be_present
        expect(json_response['issues_access_level']).to be_present
        expect(json_response['merge_requests_access_level']).to be_present
        expect(json_response['wiki_access_level']).to be_present
        expect(json_response['builds_access_level']).to be_present
        expect(json_response['resolve_outdated_diff_discussions']).to eq(project.resolve_outdated_diff_discussions)
        expect(json_response['remove_source_branch_after_merge']).to be_truthy
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
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['shared_with_groups'][0]['expires_at']).to be_nil
        expect(json_response['only_allow_merge_if_pipeline_succeeds']).to eq(project.only_allow_merge_if_pipeline_succeeds)
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
        expect(json_response['ci_default_git_depth']).to eq(project.ci_default_git_depth)
        expect(json_response['merge_method']).to eq(project.merge_method.to_s)
        expect(json_response['readme_url']).to eq(project.readme_url)
      end

      it 'returns a group link with expiration date' do
        group = create(:group)
        expires_at = 5.days.from_now.to_date
        link = create(:project_group_link, project: project, group: group, expires_at: expires_at)

        get api("/projects/#{project.id}", user)

        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_full_path']).to eq(group.full_path)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['shared_with_groups'][0]['expires_at']).to eq(expires_at.to_s)
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
          'parent_id' => nil,
          'avatar_url' => user.avatar_url,
          'web_url' => Gitlab::Routing.url_helpers.user_url(user)
        })
      end

      it "does not include license fields by default" do
        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include('license', 'license_url')
      end

      it 'includes license fields when requested' do
        get api("/projects/#{project.id}", user), params: { license: true }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['license']).to eq({
          'key' => project.repository.license.key,
          'name' => project.repository.license.name,
          'nickname' => project.repository.license.nickname,
          'html_url' => project.repository.license.url,
          'source_url' => project.repository.license.meta['source']
        })
      end

      it "does not include statistics by default" do
        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to include 'statistics'
      end

      it "includes statistics if requested" do
        get api("/projects/#{project.id}", user), params: { statistics: true }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include 'statistics'
      end

      context "and the project has a private repository" do
        let(:project) { create(:project, :public, :repository, :repository_private) }

        it "does not include statistics if user is not a member" do
          get api("/projects/#{project.id}", user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).not_to include 'statistics'
        end

        it "includes statistics if user is a member" do
          project.add_developer(user)

          get api("/projects/#{project.id}", user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to include 'statistics'
        end

        it "includes statistics also when repository is disabled" do
          project.add_developer(user)
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

          get api("/projects/#{project.id}", user), params: { statistics: true }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to include 'statistics'
        end
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

      it 'returns 404 when project is marked for deletion' do
        project.update(pending_delete: true)

        get api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
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

      context 'the project is a fork' do
        it 'shows details of a visible fork parent' do
          fork = fork_project(project, user)

          get api("/projects/#{fork.id}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['forked_from_project']).to include('id' => project.id)
        end

        it 'hides details of a hidden fork parent' do
          fork = fork_project(project, user)
          fork_user = create(:user)
          fork.team.add_developer(fork_user)

          get api("/projects/#{fork.id}", fork_user)

          expect(response).to have_gitlab_http_status(200)
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

            expect(response).to have_gitlab_http_status(200)
            expect(json_response.first['permissions']['project_access']['access_level'])
            .to eq(Gitlab::Access::MAINTAINER)
            expect(json_response.first['permissions']['group_access']).to be_nil
          end
        end

        context 'personal project' do
          it 'sets project access and returns 200' do
            project.add_maintainer(user)
            get api("/projects/#{project.id}", user)

            expect(response).to have_gitlab_http_status(200)
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

            expect(response).to have_gitlab_http_status(200)
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

            expect(response).to have_gitlab_http_status(200)
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

              expect(response).to have_gitlab_http_status(200)
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
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(200)

          group_data = json_response['namespace']
          expect(group_data['web_url']).to eq(group.web_url)
          expect(group_data['avatar_url']).to eq(group.avatar_url)
        end
      end

      context 'when project belongs to a user namespace' do
        let(:user) { create(:user) }
        let(:project) { create(:project, namespace: user.namespace) }

        it 'returns user web_url and avatar_url' do
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(200)

          user_data = json_response['namespace']
          expect(user_data['web_url']).to eq("http://localhost/#{user.username}")
          expect(user_data['avatar_url']).to eq(user.avatar_url)
        end
      end
    end

    it_behaves_like 'storing arguments in the application context' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, :public) }
      let(:expected_params) { { user: user.username, project: project.full_path } }

      subject { get api("/projects/#{project.id}", user) }
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

      it 'filters out users listed in skip_users' do
        other_user = create(:user)
        project.team.add_developer(other_user)

        get api("/projects/#{project.id}/users?skip_users=#{user.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(1)
        expect(json_response[0]['id']).to eq(other_user.id)
      end
    end
  end

  describe 'fork management' do
    let(:project_fork_target) { create(:project) }
    let(:project_fork_source) { create(:project, :public) }
    let(:private_project_fork_source) { create(:project, :private) }

    describe 'POST /projects/:id/fork/:forked_from_id' do
      context 'user is a developer' do
        before do
          project_fork_target.add_developer(user)
        end

        it 'denies project to be forked from an existing project' do
          post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      it 'refreshes the forks count cache' do
        expect(project_fork_source.forks_count).to be_zero
      end

      context 'user is maintainer' do
        before do
          project_fork_target.add_maintainer(user)
        end

        it 'allows project to be forked from an existing project' do
          expect(project_fork_target).not_to be_forked

          post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", user)
          project_fork_target.reload

          expect(response).to have_gitlab_http_status(201)
          expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
          expect(project_fork_target.fork_network_member).to be_present
          expect(project_fork_target).to be_forked
        end

        it 'denies project to be forked from a private project' do
          post api("/projects/#{project_fork_target.id}/fork/#{private_project_fork_source.id}", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'user is admin' do
        it 'allows project to be forked from an existing project' do
          expect(project_fork_target).not_to be_forked

          post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)

          expect(response).to have_gitlab_http_status(201)
        end

        it 'allows project to be forked from a private project' do
          post api("/projects/#{project_fork_target.id}/fork/#{private_project_fork_source.id}", admin)

          expect(response).to have_gitlab_http_status(201)
        end

        it 'refreshes the forks count cachce' do
          expect do
            post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
          end.to change(project_fork_source, :forks_count).by(1)
        end

        it 'fails if forked_from project which does not exist' do
          post api("/projects/#{project_fork_target.id}/fork/0", admin)
          expect(response).to have_gitlab_http_status(404)
        end

        it 'fails with 409 if already forked' do
          other_project_fork_source = create(:project, :public)

          Projects::ForkService.new(project_fork_source, admin).execute(project_fork_target)

          post api("/projects/#{project_fork_target.id}/fork/#{other_project_fork_source.id}", admin)
          project_fork_target.reload

          expect(response).to have_gitlab_http_status(409)
          expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
          expect(project_fork_target).to be_forked
        end
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
            expect(project_fork_target.forked_from_project).to be_present
            expect(project_fork_target).to be_forked
          end

          it 'makes forked project unforked' do
            delete api("/projects/#{project_fork_target.id}/fork", admin)

            expect(response).to have_gitlab_http_status(204)
            project_fork_target.reload
            expect(project_fork_target.forked_from_project).to be_nil
            expect(project_fork_target).not_to be_forked
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
          expect(private_fork.forked_from_project).to be_present
          expect(private_fork).to be_forked
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

    before do
      group.add_developer(user)
    end

    it "shares project with group" do
      expires_at = 10.days.from_now.to_date

      expect do
        post api("/projects/#{project.id}/share", user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER, expires_at: expires_at }
      end.to change { ProjectGroupLink.count }.by(1)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['group_id']).to eq(group.id)
      expect(json_response['group_access']).to eq(Gitlab::Access::DEVELOPER)
      expect(json_response['expires_at']).to eq(expires_at.to_s)
    end

    it "returns a 400 error when group id is not given" do
      post api("/projects/#{project.id}/share", user), params: { group_access: Gitlab::Access::DEVELOPER }
      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 error when access level is not given" do
      post api("/projects/#{project.id}/share", user), params: { group_id: group.id }
      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 error when sharing is disabled" do
      project.namespace.update(share_with_group_lock: true)
      post api("/projects/#{project.id}/share", user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER }
      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns a 404 error when user cannot read group' do
      private_group = create(:group, :private)

      post api("/projects/#{project.id}/share", user), params: { group_id: private_group.id, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 error when group does not exist' do
      post api("/projects/#{project.id}/share", user), params: { group_id: 1234, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns a 400 error when wrong params passed" do
      post api("/projects/#{project.id}/share", user), params: { group_id: group.id, group_access: 1234 }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq 'group_access does not have a valid value'
    end

    it "returns a 409 error when link is not saved" do
      allow(::Projects::GroupLinks::CreateService).to receive_message_chain(:new, :execute)
        .and_return({ status: :error, http_status: 409, message: 'error' })

      post api("/projects/#{project.id}/share", user), params: { group_id: group.id, group_access: Gitlab::Access::DEVELOPER }

      expect(response).to have_gitlab_http_status(409)
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

      put api("/projects/#{project.id}", user), params: project_param

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to match('at least one parameter must be provided')
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        project_param = { name: 'bar' }

        put api("/projects/#{project.id}"), params: project_param

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated as project owner' do
      it 'updates name' do
        project_param = { name: 'bar' }

        put api("/projects/#{project.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level' do
        project_param = { visibility: 'public' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level from public to private' do
        project3.update({ visibility_level: Gitlab::VisibilityLevel::PUBLIC })
        project_param = { visibility: 'private' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end

        expect(json_response['visibility']).to eq('private')
      end

      it 'does not update name to existing name' do
        project_param = { name: project3.name }

        put api("/projects/#{project.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['name']).to eq(['has already been taken'])
      end

      it 'updates request_access_enabled' do
        project_param = { request_access_enabled: false }

        put api("/projects/#{project.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['request_access_enabled']).to eq(false)
      end

      it 'updates path & name to existing path & name in different namespace' do
        project_param = { path: project4.path, name: project4.name }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates jobs_enabled' do
        project_param = { jobs_enabled: true }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates builds_access_level' do
        project_param = { builds_access_level: 'private' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['builds_access_level']).to eq('private')
      end

      it 'updates build_git_strategy' do
        project_param = { build_git_strategy: 'clone' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['build_git_strategy']).to eq('clone')
      end

      it 'rejects to update build_git_strategy when build_git_strategy is invalid' do
        project_param = { build_git_strategy: 'invalid' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(400)
      end

      it 'updates merge_method' do
        project_param = { merge_method: 'ff' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'rejects to update merge_method when merge_method is invalid' do
        project_param = { merge_method: 'invalid' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(400)
      end

      it 'updates avatar' do
        project_param = {
          avatar: fixture_file_upload('spec/fixtures/banana_sample.gif',
                                      'image/gif')
        }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['avatar_url']).to eq('http://localhost/uploads/'\
                                                  '-/system/project/avatar/'\
                                                  "#{project3.id}/banana_sample.gif")
      end

      it 'updates auto_devops_deploy_strategy' do
        project_param = { auto_devops_deploy_strategy: 'timed_incremental' }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['auto_devops_deploy_strategy']).to eq('timed_incremental')
      end

      it 'updates auto_devops_enabled' do
        project_param = { auto_devops_enabled: false }

        put api("/projects/#{project3.id}", user), params: project_param

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['auto_devops_enabled']).to eq(false)
      end
    end

    context 'when authenticated as project maintainer' do
      it 'updates path' do
        project_param = { path: 'bar' }
        put api("/projects/#{project3.id}", user4), params: project_param
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
                          ci_default_git_depth: 20,
                          description: 'new description' }

        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'does not update path to existing path' do
        project_param = { path: project.path }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'does not update name' do
        project_param = { name: 'bar' }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not update visibility_level' do
        project_param = { visibility: 'public' }
        put api("/projects/#{project3.id}", user4), params: project_param
        expect(response).to have_gitlab_http_status(403)
      end

      it 'updates container_expiration_policy' do
        project_param = {
          container_expiration_policy_attributes: {
            cadence: '1month',
            keep_n: 1
          }
        }

        put api("/projects/#{project3.id}", user4), params: project_param

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['container_expiration_policy']['cadence']).to eq('1month')
        expect(json_response['container_expiration_policy']['keep_n']).to eq(1)
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
        put api("/projects/#{project.id}", user3), params: project_param
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
        ::Projects::UpdateService.new(project, user, archived: true).execute
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
        ::Projects::UpdateService.new(project, user, archived: true).execute
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

  describe 'GET /projects/:id/starrers' do
    shared_examples_for 'project starrers response' do
      it 'returns an array of starrers' do
        get api("/projects/#{public_project.id}/starrers", current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response[0]['starred_since']).to be_present
        expect(json_response[0]['user']).to be_present
      end

      it 'returns the proper security headers' do
        get api('/projects/1/starrers', current_user)

        expect(response).to include_security_headers
      end
    end

    let(:public_project) { create(:project, :public) }
    let(:private_user) { create(:user, private_profile: true) }

    before do
      user.update(starred_projects: [public_project])
      private_user.update(starred_projects: [public_project])
    end

    it 'returns not_found(404) for not existing project' do
      get api("/projects/9999999999/starrers", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'public project without user' do
      it_behaves_like 'project starrers response' do
        let(:current_user) { nil }
      end

      it 'returns only starrers with a public profile' do
        get api("/projects/#{public_project.id}/starrers", nil)

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
        get api("/projects/#{public_project.id}/starrers", private_user)

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
        get api("/projects/0/languages", user)

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

    let(:project2) do
      create(:project, :repository, creator: user, namespace: user.namespace)
    end

    let(:group) { create(:group) }
    let(:group2) do
      group = create(:group, name: 'group2_name')
      group.add_maintainer(user2)
      group
    end

    let(:group3) do
      group = create(:group, name: 'group3_name', parent: group2)
      group.add_owner(user2)
      group
    end

    before do
      project.add_reporter(user2)
      project2.add_reporter(user2)
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
        post api("/projects/#{project.id}/fork", user2), params: { namespace: user2.namespace.id }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks with explicit own user name as namespace' do
        post api("/projects/#{project.id}/fork", user2), params: { namespace: user2.username }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks to another user when admin' do
        post api("/projects/#{project.id}/fork", admin), params: { namespace: user2.username }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'fails if trying to fork to another user when not admin' do
        post api("/projects/#{project.id}/fork", user2), params: { namespace: admin.namespace.id }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'fails if trying to fork to non-existent namespace' do
        post api("/projects/#{project.id}/fork", user2), params: { namespace: 42424242 }

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Target Namespace Not Found')
      end

      it 'forks to owned group' do
        post api("/projects/#{project.id}/fork", user2), params: { namespace: group2.name }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group2.name)
      end

      it 'forks to owned subgroup' do
        full_path = "#{group2.path}/#{group3.path}"
        post api("/projects/#{project.id}/fork", user2), params: { namespace: full_path }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group3.name)
        expect(json_response['namespace']['full_path']).to eq(full_path)
      end

      it 'fails to fork to not owned group' do
        post api("/projects/#{project.id}/fork", user2), params: { namespace: group.name }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'forks to not owned group when admin' do
        post api("/projects/#{project.id}/fork", admin), params: { namespace: group.name }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['namespace']['name']).to eq(group.name)
      end

      it 'accepts a path for the target project' do
        post api("/projects/#{project.id}/fork", user2), params: { path: 'foobar' }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq('foobar')
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'fails to fork if path is already taken' do
        post api("/projects/#{project.id}/fork", user2), params: { path: 'foobar' }
        post api("/projects/#{project2.id}/fork", user2), params: { path: 'foobar' }

        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'accepts a name for the target project' do
        post api("/projects/#{project.id}/fork", user2), params: { name: 'My Random Project' }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq('My Random Project')
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
        expect(json_response['import_status']).to eq('scheduled')
        expect(json_response).to include("import_error")
      end

      it 'fails to fork if name is already taken' do
        post api("/projects/#{project.id}/fork", user2), params: { name: 'My Random Project' }
        post api("/projects/#{project2.id}/fork", user2), params: { name: 'My Random Project' }

        expect(response).to have_gitlab_http_status(409)
        expect(json_response['message']['name']).to eq(['has already been taken'])
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
      allow(Projects::HousekeepingService).to receive(:new).with(project, :gc).and_return(housekeeping)
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

  describe 'PUT /projects/:id/transfer' do
    context 'when authenticated as owner' do
      let(:group) { create :group }

      it 'transfers the project to the new namespace' do
        group.add_owner(user)

        put api("/projects/#{project.id}/transfer", user), params: { namespace: group.id }

        expect(response).to have_gitlab_http_status(200)
      end

      it 'fails when transferring to a non owned namespace' do
        put api("/projects/#{project.id}/transfer", user), params: { namespace: group.id }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'fails when transferring to an unknown namespace' do
        put api("/projects/#{project.id}/transfer", user), params: { namespace: 'unknown' }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'fails on missing namespace' do
        put api("/projects/#{project.id}/transfer", user)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when authenticated as developer' do
      before do
        group.add_developer(user)
      end

      context 'target namespace allows developers to create projects' do
        let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

        it 'fails transferring the project to the target namespace' do
          put api("/projects/#{project.id}/transfer", user), params: { namespace: group.id }

          expect(response).to have_gitlab_http_status(400)
        end
      end
    end
  end

  it_behaves_like 'custom attributes endpoints', 'projects' do
    let(:attributable) { project }
    let(:other_attributable) { project2 }
  end
end
