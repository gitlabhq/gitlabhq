# -*- coding: utf-8 -*-
require 'spec_helper'

describe API::Projects, api: true  do
  include ApiHelpers
  include Gitlab::CurrentSettings
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:empty_project, creator_id: user.id, namespace: user.namespace) }
  let(:project2) { create(:empty_project, path: 'project2', creator_id: user.id, namespace: user.namespace) }
  let(:snippet) { create(:project_snippet, :public, author: user, project: project, title: 'example') }
  let(:project_member) { create(:project_member, :master, user: user, project: project) }
  let(:project_member2) { create(:project_member, :developer, user: user3, project: project) }
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
    snippets_enabled: false)
  end
  let(:project_member3) do
    create(:project_member,
    user: user4,
    project: project3,
    access_level: ProjectMember::MASTER)
  end
  let(:project4) do
    create(:empty_project,
    name: 'third_project',
    path: 'third_project',
    creator_id: user4.id,
    namespace: user4.namespace)
  end

  describe 'GET /projects' do
    shared_examples_for 'projects response' do
      it 'returns an array of projects' do
        get api('/projects', current_user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.map { |p| p['id'] }).to contain_exactly(*projects.map(&:id))
      end
    end

    let!(:public_project) { create(:empty_project, :public, name: 'public_project') }
    before do
      project
      project2
      project3
      project4
    end

    context 'when unauthenticated' do
      it_behaves_like 'projects response' do
        let(:current_user) { nil }
        let(:projects) { [public_project] }
      end
    end

    context 'when authenticated as regular user' do
      it_behaves_like 'projects response' do
        let(:current_user) { user }
        let(:projects) { [public_project, project, project2, project3] }
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

      it "does not include statistics by default" do
        get api('/projects', user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).not_to include('statistics')
      end

      it "includes statistics if requested" do
        get api('/projects', user), statistics: true

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first).to include 'statistics'
      end

      context 'and with simple=true' do
        it 'returns a simplified version of all the projects' do
          expected_keys = %w(id http_url_to_repo web_url name name_with_namespace path path_with_namespace)

          get api('/projects?simple=true', user)

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first.keys).to match_array expected_keys
        end
      end

      context 'and using search' do
        it 'returns searched project' do
          get api('/projects', user), { search: project.name }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end

      context 'and using the visibility filter' do
        it 'filters based on private visibility param' do
          get api('/projects', user), { visibility: 'private' }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project.id, project2.id, project3.id)
        end

        it 'filters based on internal visibility param' do
          project2.update_attribute(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)

          get api('/projects', user), { visibility: 'internal' }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(project2.id)
        end

        it 'filters based on public visibility param' do
          get api('/projects', user), { visibility: 'public' }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |p| p['id'] }).to contain_exactly(public_project.id)
        end
      end

      context 'and using sorting' do
        it 'returns the correct order when sorted by id' do
          get api('/projects', user), { order_by: 'id', sort: 'desc' }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['id']).to eq(project3.id)
        end
      end

      context 'and with owned=true' do
        it 'returns an array of projects the user owns' do
          get api('/projects', user4), owned: true

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['name']).to eq(project4.name)
          expect(json_response.first['owner']['username']).to eq(user4.username)
        end
      end

      context 'and with starred=true' do
        let(:public_project) { create(:empty_project, :public) }

        before do
          project_member2
          user3.update_attributes(starred_projects: [project, project2, project3, public_project])
        end

        it 'returns the starred projects viewable by the user' do
          get api('/projects', user3), starred: true

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.map { |project| project['id'] }).to contain_exactly(project.id, public_project.id)
        end
      end

      context 'and with all query parameters' do
        # |         | project5 | project6 | project7 | project8 | project9 |
        # |---------+----------+----------+----------+----------+----------|
        # | search  | x        |          | x        | x        | x        |
        # | starred | x        | x        |          | x        | x        |
        # | public  | x        | x        | x        |          | x        |
        # | owned   | x        | x        | x        | x        |          |
        let!(:project5) { create(:empty_project, :public, path: 'gitlab5', namespace: user.namespace) }
        let!(:project6) { create(:empty_project, :public, path: 'project6', namespace: user.namespace) }
        let!(:project7) { create(:empty_project, :public, path: 'gitlab7', namespace: user.namespace) }
        let!(:project8) { create(:empty_project, path: 'gitlab8', namespace: user.namespace) }
        let!(:project9) { create(:empty_project, :public, path: 'gitlab9') }

        before do
          user.update_attributes(starred_projects: [project5, project6, project8, project9])
        end

        it 'returns only projects that satify all query parameters' do
          get api('/projects', user), { visibility: 'public', owned: true, starred: true, search: 'gitlab' }

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(1)
          expect(json_response.first['id']).to eq(project5.id)
        end
      end
    end

    context 'when authenticated as a different user' do
      it_behaves_like 'projects response' do
        let(:current_user) { user2 }
        let(:projects) { [public_project] }
      end
    end

    context 'when authenticated as admin' do
      it_behaves_like 'projects response' do
        let(:current_user) { admin }
        let(:projects) { Project.all }
      end
    end
  end

  describe 'POST /projects' do
    context 'maximum number of projects reached' do
      it 'does not create new project and respond with 403' do
        allow_any_instance_of(User).to receive(:projects_limit_left).and_return(0)
        expect { post api('/projects', user2), name: 'foo' }.
          to change {Project.count}.by(0)
        expect(response).to have_http_status(403)
      end
    end

    it 'creates new project without path and return 201' do
      expect { post api('/projects', user), name: 'foo' }.
        to change { Project.count }.by(1)
      expect(response).to have_http_status(201)
    end

    it 'creates last project before reaching project limit' do
      allow_any_instance_of(User).to receive(:projects_limit_left).and_return(1)
      post api('/projects', user2), name: 'foo'
      expect(response).to have_http_status(201)
    end

    it 'does not create new project without name and return 400' do
      expect { post api('/projects', user) }.not_to change { Project.count }
      expect(response).to have_http_status(400)
    end

    it "assigns attributes to project" do
      project = attributes_for(:project, {
        path: 'camelCasePath',
        description: FFaker::Lorem.sentence,
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false,
        only_allow_merge_if_build_succeeds: false,
        request_access_enabled: true,
        only_allow_merge_if_all_discussions_are_resolved: false
      })

      post api('/projects', user), project

      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker issues_enabled merge_requests_enabled wiki_enabled].include?(k)
        expect(json_response[k.to_s]).to eq(v)
      end

      # Check feature permissions attributes
      project = Project.find_by_path(project[:path])
      expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::DISABLED)
      expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::DISABLED)
    end

    it 'sets a project as public' do
      project = attributes_for(:project, :public)
      post api('/projects', user), project
      expect(json_response['public']).to be_truthy
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, :internal)
      post api('/projects', user), project
      expect(json_response['public']).to be_falsey
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it 'sets a project as private' do
      project = attributes_for(:project, :private)
      post api('/projects', user), project
      expect(json_response['public']).to be_falsey
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, { only_allow_merge_if_build_succeeds: false })
      post api('/projects', user), project
      expect(json_response['only_allow_merge_if_build_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if build succeeds' do
      project = attributes_for(:project, { only_allow_merge_if_build_succeeds: true })
      post api('/projects', user), project
      expect(json_response['only_allow_merge_if_build_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, { only_allow_merge_if_all_discussions_are_resolved: false })

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge if only_allow_merge_if_all_discussions_are_resolved is nil' do
      project = attributes_for(:project, only_allow_merge_if_all_discussions_are_resolved: nil)

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, { only_allow_merge_if_all_discussions_are_resolved: true })

      post api('/projects', user), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end

    context 'when a visibility level is restricted' do
      let(:project_param) { attributes_for(:project, :public) }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'does not allow a non-admin to use a restricted visibility level' do
        post api('/projects', user), project_param

        expect(response).to have_http_status(400)
        expect(json_response['message']['visibility_level'].first).to(
          match('restricted by your GitLab administrator')
        )
      end

      it 'allows an admin to override restricted visibility settings' do
        post api('/projects', admin), project_param

        expect(json_response['public']).to be_truthy
        expect(json_response['visibility_level']).to(
          eq(Gitlab::VisibilityLevel::PUBLIC)
        )
      end
    end
  end

  describe 'POST /projects/user/:id' do
    before { project }
    before { admin }

    it 'creates new project without path and return 201' do
      expect { post api("/projects/user/#{user.id}", admin), name: 'foo' }.to change {Project.count}.by(1)
      expect(response).to have_http_status(201)
    end

    it 'responds with 400 on failure and not project' do
      expect { post api("/projects/user/#{user.id}", admin) }.
        not_to change { Project.count }

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'assigns attributes to project' do
      project = attributes_for(:project, {
        description: FFaker::Lorem.sentence,
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false,
        request_access_enabled: true
      })

      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_http_status(201)
      project.each_pair do |k, v|
        next if %i[has_external_issue_tracker path].include?(k)
        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it 'sets a project as public' do
      project = attributes_for(:project, :public)
      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_http_status(201)
      expect(json_response['public']).to be_truthy
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'sets a project as internal' do
      project = attributes_for(:project, :internal)
      post api("/projects/user/#{user.id}", admin), project

      expect(response).to have_http_status(201)
      expect(json_response['public']).to be_falsey
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it 'sets a project as private' do
      project = attributes_for(:project, :private)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_falsey
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'sets a project as allowing merge even if build fails' do
      project = attributes_for(:project, { only_allow_merge_if_build_succeeds: false })
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['only_allow_merge_if_build_succeeds']).to be_falsey
    end

    it 'sets a project as allowing merge only if build succeeds' do
      project = attributes_for(:project, { only_allow_merge_if_build_succeeds: true })
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['only_allow_merge_if_build_succeeds']).to be_truthy
    end

    it 'sets a project as allowing merge even if discussions are unresolved' do
      project = attributes_for(:project, { only_allow_merge_if_all_discussions_are_resolved: false })

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_falsey
    end

    it 'sets a project as allowing merge only if all discussions are resolved' do
      project = attributes_for(:project, { only_allow_merge_if_all_discussions_are_resolved: true })

      post api("/projects/user/#{user.id}", admin), project

      expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to be_truthy
    end
  end

  describe "POST /projects/:id/uploads" do
    before { project }

    it "uploads the file and returns its info" do
      post api("/projects/#{project.id}/uploads", user), file: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")

      expect(response).to have_http_status(201)
      expect(json_response['alt']).to eq("dk")
      expect(json_response['url']).to start_with("/uploads/")
      expect(json_response['url']).to end_with("/dk.png")
    end
  end

  describe 'GET /projects/:id' do
    context 'when unauthenticated' do
      it 'returns the public projects' do
        public_project = create(:empty_project, :public)

        get api("/projects/#{public_project.id}")

        expect(response).to have_http_status(200)
        expect(json_response['id']).to eq(public_project.id)
        expect(json_response['description']).to eq(public_project.description)
        expect(json_response.keys).not_to include('permissions')
      end
    end

    context 'when authenticated' do
      before do
        project
        project_member
      end

      it 'returns a project by id' do
        group = create(:group)
        link = create(:project_group_link, project: project, group: group)

        get api("/projects/#{project.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['id']).to eq(project.id)
        expect(json_response['description']).to eq(project.description)
        expect(json_response['default_branch']).to eq(project.default_branch)
        expect(json_response['tag_list']).to be_an Array
        expect(json_response['public']).to be_falsey
        expect(json_response['archived']).to be_falsey
        expect(json_response['visibility_level']).to be_present
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
        expect(json_response['builds_enabled']).to be_present
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
        expect(json_response['public_builds']).to be_present
        expect(json_response['shared_with_groups']).to be_an Array
        expect(json_response['shared_with_groups'].length).to eq(1)
        expect(json_response['shared_with_groups'][0]['group_id']).to eq(group.id)
        expect(json_response['shared_with_groups'][0]['group_name']).to eq(group.name)
        expect(json_response['shared_with_groups'][0]['group_access_level']).to eq(link.group_access)
        expect(json_response['only_allow_merge_if_build_succeeds']).to eq(project.only_allow_merge_if_build_succeeds)
        expect(json_response['only_allow_merge_if_all_discussions_are_resolved']).to eq(project.only_allow_merge_if_all_discussions_are_resolved)
      end

      it 'returns a project by path name' do
        get api("/projects/#{project.id}", user)
        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(project.name)
      end

      it 'returns a 404 error if not found' do
        get api('/projects/42', user)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)
        get api("/projects/#{project.id}", other_user)
        expect(response).to have_http_status(404)
      end

      it 'handles users with dots' do
        dot_user = create(:user, username: 'dot.user')
        project = create(:empty_project, creator_id: dot_user.id, namespace: dot_user.namespace)

        get api("/projects/#{dot_user.namespace.name}%2F#{project.path}", dot_user)
        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(project.name)
      end

      it 'exposes namespace fields' do
        get api("/projects/#{project.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['namespace']).to eq({
          'id' => user.namespace.id,
          'name' => user.namespace.name,
          'path' => user.namespace.path,
          'kind' => user.namespace.kind,
          'full_path' => user.namespace.full_path,
        })
      end

      describe 'permissions' do
        context 'all projects' do
          before { project.team << [user, :master] }

          it 'contains permission information' do
            get api("/projects", user)

            expect(response).to have_http_status(200)
            expect(json_response.first['permissions']['project_access']['access_level']).
            to eq(Gitlab::Access::MASTER)
            expect(json_response.first['permissions']['group_access']).to be_nil
          end
        end

        context 'personal project' do
          it 'sets project access and returns 200' do
            project.team << [user, :master]
            get api("/projects/#{project.id}", user)

            expect(response).to have_http_status(200)
            expect(json_response['permissions']['project_access']['access_level']).
            to eq(Gitlab::Access::MASTER)
            expect(json_response['permissions']['group_access']).to be_nil
          end
        end

        context 'group project' do
          let(:project2) { create(:empty_project, group: create(:group)) }

          before { project2.group.add_owner(user) }

          it 'sets the owner and return 200' do
            get api("/projects/#{project2.id}", user)

            expect(response).to have_http_status(200)
            expect(json_response['permissions']['project_access']).to be_nil
            expect(json_response['permissions']['group_access']['access_level']).
            to eq(Gitlab::Access::OWNER)
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/events' do
    shared_examples_for 'project events response' do
      it 'returns the project events' do
        member = create(:user)
        create(:project_member, :developer, user: member, project: project)
        note = create(:note_on_issue, note: 'What an awesome day!', project: project)
        EventCreateService.new.leave_note(note, note.author)

        get api("/projects/#{project.id}/events", current_user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        first_event = json_response.first
        expect(first_event['action_name']).to eq('commented on')
        expect(first_event['note']['body']).to eq('What an awesome day!')

        last_event = json_response.last

        expect(last_event['action_name']).to eq('joined')
        expect(last_event['project_id'].to_i).to eq(project.id)
        expect(last_event['author_username']).to eq(member.username)
        expect(last_event['author']['name']).to eq(member.name)
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'project events response' do
        let(:project) { create(:empty_project, :public) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated' do
      context 'valid request' do
        it_behaves_like 'project events response' do
          let(:current_user) { user }
        end
      end

      it 'returns a 404 error if not found' do
        get api('/projects/42/events', user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)

        get api("/projects/#{project.id}/events", other_user)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/users' do
    shared_examples_for 'project users response' do
      it 'returns the project users' do
        member = create(:user)
        create(:project_member, :developer, user: member, project: project)

        get api("/projects/#{project.id}/users", current_user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)

        first_user = json_response.first
        expect(first_user['username']).to eq(member.username)
        expect(first_user['name']).to eq(member.name)
        expect(first_user.keys).to contain_exactly(*%w[name username id state avatar_url web_url])
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'project users response' do
        let(:project) { create(:empty_project, :public) }
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

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'returns a 404 error if user is not a member' do
        other_user = create(:user)

        get api("/projects/#{project.id}/users", other_user)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /projects/:id/snippets' do
    before { snippet }

    it 'returns an array of project snippets' do
      get api("/projects/#{project.id}/snippets", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(snippet.title)
    end
  end

  describe 'GET /projects/:id/snippets/:snippet_id' do
    it 'returns a project snippet' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq(snippet.title)
    end

    it 'returns a 404 error if snippet id not found' do
      get api("/projects/#{project.id}/snippets/1234", user)
      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /projects/:id/snippets' do
    it 'creates a new project snippet' do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb', code: 'test',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      expect(response).to have_http_status(201)
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
      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq('example')
      expect(snippet.reload.content).to eq('updated code')
    end

    it 'updates an existing project snippet with new title' do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        title: 'other api test'
      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq('other api test')
    end
  end

  describe 'DELETE /projects/:id/snippets/:snippet_id' do
    before { snippet }

    it 'deletes existing project snippet' do
      expect do
        delete api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      end.to change { Snippet.count }.by(-1)
      expect(response).to have_http_status(200)
    end

    it 'returns 404 when deleting unknown snippet id' do
      delete api("/projects/#{project.id}/snippets/1234", user)
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /projects/:id/snippets/:snippet_id/raw' do
    it 'gets a raw project snippet' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/raw", user)
      expect(response).to have_http_status(200)
    end

    it 'returns a 404 error if raw project snippet not found' do
      get api("/projects/#{project.id}/snippets/5555/raw", user)
      expect(response).to have_http_status(404)
    end
  end

  describe :fork_admin do
    let(:project_fork_target) { create(:empty_project) }
    let(:project_fork_source) { create(:empty_project, :public) }

    describe 'POST /projects/:id/fork/:forked_from_id' do
      let(:new_project_fork_source) { create(:empty_project, :public) }

      it "is not available for non admin users" do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", user)
        expect(response).to have_http_status(403)
      end

      it 'allows project to be forked from an existing project' do
        expect(project_fork_target.forked?).not_to be_truthy
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        expect(response).to have_http_status(201)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked_project_link).not_to be_nil
        expect(project_fork_target.forked?).to be_truthy
      end

      it 'fails if forked_from project which does not exist' do
        post api("/projects/#{project_fork_target.id}/fork/9999", admin)
        expect(response).to have_http_status(404)
      end

      it 'fails with 409 if already forked' do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        post api("/projects/#{project_fork_target.id}/fork/#{new_project_fork_source.id}", admin)
        expect(response).to have_http_status(409)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked?).to be_truthy
      end
    end

    describe 'DELETE /projects/:id/fork' do
      it "is not visible to users outside group" do
        delete api("/projects/#{project_fork_target.id}/fork", user)
        expect(response).to have_http_status(404)
      end

      context 'when users belong to project group' do
        let(:project_fork_target) { create(:empty_project, group: create(:group)) }

        before do
          project_fork_target.group.add_owner user
          project_fork_target.group.add_developer user2
        end

        it 'is forbidden to non-owner users' do
          delete api("/projects/#{project_fork_target.id}/fork", user2)
          expect(response).to have_http_status(403)
        end

        it 'makes forked project unforked' do
          post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
          project_fork_target.reload
          expect(project_fork_target.forked_from_project).not_to be_nil
          expect(project_fork_target.forked?).to be_truthy
          delete api("/projects/#{project_fork_target.id}/fork", admin)
          expect(response).to have_http_status(200)
          project_fork_target.reload
          expect(project_fork_target.forked_from_project).to be_nil
          expect(project_fork_target.forked?).not_to be_truthy
        end

        it 'is idempotent if not forked' do
          expect(project_fork_target.forked_from_project).to be_nil
          delete api("/projects/#{project_fork_target.id}/fork", admin)
          expect(response).to have_http_status(304)
          expect(project_fork_target.reload.forked_from_project).to be_nil
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

      expect(response).to have_http_status(201)
      expect(json_response['group_id']).to eq(group.id)
      expect(json_response['group_access']).to eq(Gitlab::Access::DEVELOPER)
      expect(json_response['expires_at']).to eq(expires_at.to_s)
    end

    it "returns a 400 error when group id is not given" do
      post api("/projects/#{project.id}/share", user), group_access: Gitlab::Access::DEVELOPER
      expect(response).to have_http_status(400)
    end

    it "returns a 400 error when access level is not given" do
      post api("/projects/#{project.id}/share", user), group_id: group.id
      expect(response).to have_http_status(400)
    end

    it "returns a 400 error when sharing is disabled" do
      project.namespace.update(share_with_group_lock: true)
      post api("/projects/#{project.id}/share", user), group_id: group.id, group_access: Gitlab::Access::DEVELOPER
      expect(response).to have_http_status(400)
    end

    it 'returns a 404 error when user cannot read group' do
      private_group = create(:group, :private)

      post api("/projects/#{project.id}/share", user), group_id: private_group.id, group_access: Gitlab::Access::DEVELOPER

      expect(response).to have_http_status(404)
    end

    it 'returns a 404 error when group does not exist' do
      post api("/projects/#{project.id}/share", user), group_id: 1234, group_access: Gitlab::Access::DEVELOPER

      expect(response).to have_http_status(404)
    end

    it "returns a 400 error when wrong params passed" do
      post api("/projects/#{project.id}/share", user), group_id: group.id, group_access: 1234

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq 'group_access does not have a valid value'
    end
  end

  describe 'DELETE /projects/:id/share/:group_id' do
    it 'returns 204 when deleting a group share' do
      group = create(:group, :public)
      create(:project_group_link, group: group, project: project)

      delete api("/projects/#{project.id}/share/#{group.id}", user)

      expect(response).to have_http_status(204)
      expect(project.project_group_links).to be_empty
    end

    it 'returns a 400 when group id is not an integer' do
      delete api("/projects/#{project.id}/share/foo", user)

      expect(response).to have_http_status(400)
    end

    it 'returns a 404 error when group link does not exist' do
      delete api("/projects/#{project.id}/share/1234", user)

      expect(response).to have_http_status(404)
    end

    it 'returns a 404 error when project does not exist' do
      delete api("/projects/123/share/1234", user)

      expect(response).to have_http_status(404)
    end
  end

  describe 'PUT /projects/:id' do
    before { project }
    before { user }
    before { user3 }
    before { user4 }
    before { project3 }
    before { project4 }
    before { project_member3 }
    before { project_member2 }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        project_param = { name: 'bar' }
        put api("/projects/#{project.id}"), project_param
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated as project owner' do
      it 'updates name' do
        project_param = { name: 'bar' }
        put api("/projects/#{project.id}", user), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level' do
        project_param = { visibility_level: Gitlab::VisibilityLevel::PUBLIC }
        put api("/projects/#{project3.id}", user), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates visibility_level from public to private' do
        project3.update_attributes({ visibility_level: Gitlab::VisibilityLevel::PUBLIC })
        project_param = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }
        put api("/projects/#{project3.id}", user), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
        expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'does not update name to existing name' do
        project_param = { name: project3.name }
        put api("/projects/#{project.id}", user), project_param
        expect(response).to have_http_status(400)
        expect(json_response['message']['name']).to eq(['has already been taken'])
      end

      it 'updates request_access_enabled' do
        project_param = { request_access_enabled: false }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_http_status(200)
        expect(json_response['request_access_enabled']).to eq(false)
      end

      it 'updates approvals_before_merge' do
        project_param = { approvals_before_merge: 3 }

        put api("/projects/#{project.id}", user), project_param

        expect(response).to have_http_status(200)
        expect(json_response['approvals_before_merge']).to eq(3)
      end

      it 'updates path & name to existing path & name in different namespace' do
        project_param = { path: project4.path, name: project4.name }
        put api("/projects/#{project3.id}", user), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end
    end

    context 'when authenticated as project master' do
      it 'updates path' do
        project_param = { path: 'bar' }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'updates other attributes' do
        project_param = { issues_enabled: true,
                          wiki_enabled: true,
                          snippets_enabled: true,
                          merge_requests_enabled: true,
                          description: 'new description' }

        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_http_status(200)
        project_param.each_pair do |k, v|
          expect(json_response[k.to_s]).to eq(v)
        end
      end

      it 'does not update path to existing path' do
        project_param = { path: project.path }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_http_status(400)
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'does not update name' do
        project_param = { name: 'bar' }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_http_status(403)
      end

      it 'does not update visibility_level' do
        project_param = { visibility_level: Gitlab::VisibilityLevel::PUBLIC }
        put api("/projects/#{project3.id}", user4), project_param
        expect(response).to have_http_status(403)
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
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/archive' do
    context 'on an unarchived project' do
      it 'archives the project' do
        post api("/projects/#{project.id}/archive", user)

        expect(response).to have_http_status(201)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'on an archived project' do
      before do
        project.archive!
      end

      it 'remains archived' do
        post api("/projects/#{project.id}/archive", user)

        expect(response).to have_http_status(201)
        expect(json_response['archived']).to be_truthy
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.team << [user3, :developer]
      end

      it 'rejects the action' do
        post api("/projects/#{project.id}/archive", user3)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/unarchive' do
    context 'on an unarchived project' do
      it 'remains unarchived' do
        post api("/projects/#{project.id}/unarchive", user)

        expect(response).to have_http_status(201)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'on an archived project' do
      before do
        project.archive!
      end

      it 'unarchives the project' do
        post api("/projects/#{project.id}/unarchive", user)

        expect(response).to have_http_status(201)
        expect(json_response['archived']).to be_falsey
      end
    end

    context 'user without archiving rights to the project' do
      before do
        project.team << [user3, :developer]
      end

      it 'rejects the action' do
        post api("/projects/#{project.id}/unarchive", user3)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/star' do
    context 'on an unstarred project' do
      it 'stars the project' do
        expect { post api("/projects/#{project.id}/star", user) }.to change { project.reload.star_count }.by(1)

        expect(response).to have_http_status(201)
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

        expect(response).to have_http_status(304)
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

        expect(response).to have_http_status(201)
        expect(json_response['star_count']).to eq(0)
      end
    end

    context 'on an unstarred project' do
      it 'does not modify the star count' do
        expect { post api("/projects/#{project.id}/unstar", user) }.not_to change { project.reload.star_count }

        expect(response).to have_http_status(304)
      end
    end
  end

  describe 'DELETE /projects/:id' do
    context 'when authenticated as user' do
      it 'removes project' do
        delete api("/projects/#{project.id}", user)
        expect(response).to have_http_status(200)
      end

      it 'does not remove a project if not an owner' do
        user3 = create(:user)
        project.team << [user3, :developer]
        delete api("/projects/#{project.id}", user3)
        expect(response).to have_http_status(403)
      end

      it 'does not remove a non existing project' do
        delete api('/projects/1328', user)
        expect(response).to have_http_status(404)
      end

      it 'does not remove a project not attached to user' do
        delete api("/projects/#{project.id}", user2)
        expect(response).to have_http_status(404)
      end
    end

    context 'when authenticated as admin' do
      it 'removes any existing project' do
        delete api("/projects/#{project.id}", admin)
        expect(response).to have_http_status(200)
      end

      it 'does not remove a non existing project' do
        delete api('/projects/1328', admin)
        expect(response).to have_http_status(404)
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

    before do
      project.add_reporter(user2)
    end

    context 'when authenticated' do
      it 'forks if user has sufficient access to project' do
        post api("/projects/#{project.id}/fork", user2)

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'forks if user is admin' do
        post api("/projects/#{project.id}/fork", admin)

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(admin.id)
        expect(json_response['namespace']['id']).to eq(admin.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'fails on missing project access for the project to fork' do
        new_user = create(:user)
        post api("/projects/#{project.id}/fork", new_user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'fails if forked project exists in the user namespace' do
        post api("/projects/#{project.id}/fork", user)

        expect(response).to have_http_status(409)
        expect(json_response['message']['name']).to eq(['has already been taken'])
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'fails if project to fork from does not exist' do
        post api('/projects/424242/fork', user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'forks with explicit own user namespace id' do
        post api("/projects/#{project.id}/fork", user2), namespace: user2.namespace.id

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks with explicit own user name as namespace' do
        post api("/projects/#{project.id}/fork", user2), namespace: user2.username

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks to another user when admin' do
        post api("/projects/#{project.id}/fork", admin), namespace: user2.username

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'fails if trying to fork to another user when not admin' do
        post api("/projects/#{project.id}/fork", user2), namespace: admin.namespace.id

        expect(response).to have_http_status(404)
      end

      it 'fails if trying to fork to non-existent namespace' do
        post api("/projects/#{project.id}/fork", user2), namespace: 42424242

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Target Namespace Not Found')
      end

      it 'forks to owned group' do
        post api("/projects/#{project.id}/fork", user2), namespace: group2.name

        expect(response).to have_http_status(201)
        expect(json_response['namespace']['name']).to eq(group2.name)
      end

      it 'fails to fork to not owned group' do
        post api("/projects/#{project.id}/fork", user2), namespace: group.name

        expect(response).to have_http_status(404)
      end

      it 'forks to not owned group when admin' do
        post api("/projects/#{project.id}/fork", admin), namespace: group.name

        expect(response).to have_http_status(201)
        expect(json_response['namespace']['name']).to eq(group.name)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/projects/#{project.id}/fork")

        expect(response).to have_http_status(401)
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

        expect(response).to have_http_status(201)
      end

      context 'when housekeeping lease is taken' do
        it 'returns conflict' do
          expect(housekeeping).to receive(:execute).once.and_raise(Projects::HousekeepingService::LeaseTaken)

          post api("/projects/#{project.id}/housekeeping", user)

          expect(response).to have_http_status(409)
          expect(json_response['message']).to match(/Somebody already triggered housekeeping for this project/)
        end
      end
    end

    context 'when authenticated as developer' do
      before do
        project_member2
      end

      it 'returns forbidden error' do
        post api("/projects/#{project.id}/housekeeping", user3)

        expect(response).to have_http_status(403)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/projects/#{project.id}/housekeeping")

        expect(response).to have_http_status(401)
      end
    end
  end
end
