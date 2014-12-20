require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let(:snippet) { create(:project_snippet, author: user, project: project, title: 'example') }
  let(:project_member) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let(:project_member2) { create(:project_member, user: user3, project: project, access_level: ProjectMember::DEVELOPER) }

  describe "GET /projects" do
    before { project }

    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return an array of projects" do
        get api("/projects", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(project.name)
        expect(json_response.first['owner']['username']).to eq(user.username)
      end
    end
  end

  describe "GET /projects/all" do
    before { project }

    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/all")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated as regular user" do
      it "should return authentication error" do
        get api("/projects/all", user)
        expect(response.status).to eq(403)
      end
    end

    context "when authenticated as admin" do
      it "should return an array of all projects" do
        get api("/projects/all", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        project_name = project.name

        expect(json_response.detect {
          |project| project['name'] == project_name
        }['name']).to eq(project_name)

        expect(json_response.detect {
          |project| project['owner']['username'] == user.username
        }['owner']['username']).to eq(user.username)
      end
    end
  end

  describe "POST /projects" do
    context "maximum number of projects reached" do
      before do
        (1..user2.projects_limit).each do |project|
          post api("/projects", user2), name: "foo#{project}"
        end
      end

      it "should not create new project" do
        expect {
          post api("/projects", user2), name: 'foo'
        }.to change {Project.count}.by(0)
      end
    end

    it "should create new project without path" do
      expect { post api("/projects", user), name: 'foo' }.to change {Project.count}.by(1)
    end

    it "should not create new project without name" do
      expect { post api("/projects", user) }.to_not change {Project.count}
    end

    it "should return a 400 error if name not given" do
      post api("/projects", user)
      expect(response.status).to eq(400)
    end

    it "should create last project before reaching project limit" do
      (1..user2.projects_limit-1).each { |p| post api("/projects", user2), name: "foo#{p}" }
      post api("/projects", user2), name: "foo"
      expect(response.status).to eq(201)
    end

    it "should respond with 201 on success" do
      post api("/projects", user), name: 'foo'
      expect(response.status).to eq(201)
    end

    it "should respond with 400 if name is not given" do
      post api("/projects", user)
      expect(response.status).to eq(400)
    end

    it "should return a 403 error if project limit reached" do
      (1..user.projects_limit).each do |p|
        post api("/projects", user), name: "foo#{p}"
      end
      post api("/projects", user), name: 'bar'
      expect(response.status).to eq(403)
    end

    it "should assign attributes to project" do
      project = attributes_for(:project, {
        path: 'camelCasePath',
        description: Faker::Lorem.sentence,
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false
      })

      post api("/projects", user), project

      project.each_pair do |k,v|
        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it "should set a project as public" do
      project = attributes_for(:project, :public)
      post api("/projects", user), project
      expect(json_response['public']).to be_true
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it "should set a project as public using :public" do
      project = attributes_for(:project, { public: true })
      post api("/projects", user), project
      expect(json_response['public']).to be_true
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it "should set a project as internal" do
      project = attributes_for(:project, :internal)
      post api("/projects", user), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it "should set a project as internal overriding :public" do
      project = attributes_for(:project, :internal, { public: true })
      post api("/projects", user), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it "should set a project as private" do
      project = attributes_for(:project, :private)
      post api("/projects", user), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it "should set a project as private using :public" do
      project = attributes_for(:project, { public: false })
      post api("/projects", user), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  describe "POST /projects/user/:id" do
    before { project }
    before { admin }

    it "should create new project without path" do
      expect { post api("/projects/user/#{user.id}", admin), name: 'foo' }.to change {Project.count}.by(1)
    end

    it "should not create new project without name" do
      expect { post api("/projects/user/#{user.id}", admin) }.to_not change {Project.count}
    end

    it "should respond with 201 on success" do
      post api("/projects/user/#{user.id}", admin), name: 'foo'
      expect(response.status).to eq(201)
    end

    it 'should respond with 400 on failure' do
      post api("/projects/user/#{user.id}", admin)
      expect(response.status).to eq(400)
      expect(json_response['message']['creator']).to eq(['can\'t be blank'])
      expect(json_response['message']['namespace']).to eq(['can\'t be blank'])
      expect(json_response['message']['name']).to eq([
        'can\'t be blank',
        'is too short (minimum is 0 characters)',
        Gitlab::Regex.project_regex_message
      ])
      expect(json_response['message']['path']).to eq([
        'can\'t be blank',
        'is too short (minimum is 0 characters)',
        Gitlab::Regex.send(:default_regex_message)
      ])
    end

    it "should assign attributes to project" do
      project = attributes_for(:project, {
        description: Faker::Lorem.sentence,
        issues_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false
      })

      post api("/projects/user/#{user.id}", admin), project

      project.each_pair do |k,v|
        next if k == :path
        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it "should set a project as public" do
      project = attributes_for(:project, :public)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_true
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it "should set a project as public using :public" do
      project = attributes_for(:project, { public: true })
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_true
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it "should set a project as internal" do
      project = attributes_for(:project, :internal)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it "should set a project as internal overriding :public" do
      project = attributes_for(:project, :internal, { public: true })
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    it "should set a project as private" do
      project = attributes_for(:project, :private)
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it "should set a project as private using :public" do
      project = attributes_for(:project, { public: false })
      post api("/projects/user/#{user.id}", admin), project
      expect(json_response['public']).to be_false
      expect(json_response['visibility_level']).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  describe "GET /projects/:id" do
    before { project }
    before { project_member }

    it "should return a project by id" do
      get api("/projects/#{project.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['name']).to eq(project.name)
      expect(json_response['owner']['username']).to eq(user.username)
    end

    it "should return a project by path name" do
      get api("/projects/#{project.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['name']).to eq(project.name)
    end

    it "should return a 404 error if not found" do
      get api("/projects/42", user)
      expect(response.status).to eq(404)
      expect(json_response['message']).to eq('404 Not Found')
    end

    it "should return a 404 error if user is not a member" do
      other_user = create(:user)
      get api("/projects/#{project.id}", other_user)
      expect(response.status).to eq(404)
    end

    describe 'permissions' do
      context 'personal project' do
        before do
          project.team << [user, :master]
          get api("/projects/#{project.id}", user)
        end

        it { expect(response.status).to eq(200) }
        it { expect(json_response['permissions']["project_access"]["access_level"]).to eq(Gitlab::Access::MASTER) }
        it { expect(json_response['permissions']["group_access"]).to be_nil }
      end

      context 'group project' do
        before do
          project2 = create(:project, group: create(:group))
          project2.group.add_owner(user)
          get api("/projects/#{project2.id}", user)
        end

        it { expect(response.status).to eq(200) }
        it { expect(json_response['permissions']["project_access"]).to be_nil }
        it { expect(json_response['permissions']["group_access"]["access_level"]).to eq(Gitlab::Access::OWNER) }
      end
    end
  end

  describe "GET /projects/:id/events" do
    before { project_member }

    it "should return a project events" do
      get api("/projects/#{project.id}/events", user)
      expect(response.status).to eq(200)
      json_event = json_response.first

      expect(json_event['action_name']).to eq('joined')
      expect(json_event['project_id'].to_i).to eq(project.id)
      expect(json_event['author_username']).to eq(user.username)
    end

    it "should return a 404 error if not found" do
      get api("/projects/42/events", user)
      expect(response.status).to eq(404)
      expect(json_response['message']).to eq('404 Not Found')
    end

    it "should return a 404 error if user is not a member" do
      other_user = create(:user)
      get api("/projects/#{project.id}/events", other_user)
      expect(response.status).to eq(404)
    end
  end

  describe "GET /projects/:id/snippets" do
    before { snippet }

    it "should return an array of project snippets" do
      get api("/projects/#{project.id}/snippets", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(snippet.title)
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id" do
    it "should return a project snippet" do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq(snippet.title)
    end

    it "should return a 404 error if snippet id not found" do
      get api("/projects/#{project.id}/snippets/1234", user)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects/:id/snippets" do
    it "should create a new project snippet" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb', code: 'test'
      expect(response.status).to eq(201)
      expect(json_response['title']).to eq('api test')
    end

    it "should return a 400 error if title is not given" do
      post api("/projects/#{project.id}/snippets", user),
        file_name: 'sample.rb', code: 'test'
      expect(response.status).to eq(400)
    end

    it "should return a 400 error if file_name not given" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', code: 'test'
      expect(response.status).to eq(400)
    end

    it "should return a 400 error if code not given" do
      post api("/projects/#{project.id}/snippets", user),
        title: 'api test', file_name: 'sample.rb'
      expect(response.status).to eq(400)
    end
  end

  describe "PUT /projects/:id/snippets/:shippet_id" do
    it "should update an existing project snippet" do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        code: 'updated code'
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq('example')
      expect(snippet.reload.content).to eq('updated code')
    end

    it "should update an existing project snippet with new title" do
      put api("/projects/#{project.id}/snippets/#{snippet.id}", user),
        title: 'other api test'
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq('other api test')
    end
  end

  describe "DELETE /projects/:id/snippets/:snippet_id" do
    before { snippet }

    it "should delete existing project snippet" do
      expect {
        delete api("/projects/#{project.id}/snippets/#{snippet.id}", user)
      }.to change { Snippet.count }.by(-1)
      expect(response.status).to eq(200)
    end

    it 'should return 404 when deleting unknown snippet id' do
      delete api("/projects/#{project.id}/snippets/1234", user)
      expect(response.status).to eq(404)
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id/raw" do
    it "should get a raw project snippet" do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/raw", user)
      expect(response.status).to eq(200)
    end

    it "should return a 404 error if raw project snippet not found" do
      get api("/projects/#{project.id}/snippets/5555/raw", user)
      expect(response.status).to eq(404)
    end
  end

  describe :deploy_keys do
    let(:deploy_keys_project) { create(:deploy_keys_project, project: project) }
    let(:deploy_key) { deploy_keys_project.deploy_key }

    describe "GET /projects/:id/keys" do
      before { deploy_key }

      it "should return array of ssh keys" do
        get api("/projects/#{project.id}/keys", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(deploy_key.title)
      end
    end

    describe "GET /projects/:id/keys/:key_id" do
      it "should return a single key" do
        get api("/projects/#{project.id}/keys/#{deploy_key.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['title']).to eq(deploy_key.title)
      end

      it "should return 404 Not Found with invalid ID" do
        get api("/projects/#{project.id}/keys/404", user)
        expect(response.status).to eq(404)
      end
    end

    describe "POST /projects/:id/keys" do
      it "should not create an invalid ssh key" do
        post api("/projects/#{project.id}/keys", user), { title: "invalid key" }
        expect(response.status).to eq(400)
        expect(json_response['message']['key']).to eq([
          'can\'t be blank',
          'is too short (minimum is 0 characters)',
          'is invalid'
        ])
      end

      it 'should not create a key without title' do
        post api("/projects/#{project.id}/keys", user), key: 'some key'
        expect(response.status).to eq(400)
        expect(json_response['message']['title']).to eq([
          'can\'t be blank',
          'is too short (minimum is 0 characters)'
        ])
      end

      it "should create new ssh key" do
        key_attrs = attributes_for :key
        expect {
          post api("/projects/#{project.id}/keys", user), key_attrs
        }.to change{ project.deploy_keys.count }.by(1)
      end
    end

    describe "DELETE /projects/:id/keys/:key_id" do
      before { deploy_key }

      it "should delete existing key" do
        expect {
          delete api("/projects/#{project.id}/keys/#{deploy_key.id}", user)
        }.to change{ project.deploy_keys.count }.by(-1)
      end

      it "should return 404 Not Found with invalid ID" do
        delete api("/projects/#{project.id}/keys/404", user)
        expect(response.status).to eq(404)
      end
    end
  end

  describe :fork_admin do
    let(:project_fork_target) { create(:project) }
    let(:project_fork_source) { create(:project, :public) }

    describe "POST /projects/:id/fork/:forked_from_id" do
      let(:new_project_fork_source) { create(:project, :public) }

      it "shouldn't available for non admin users" do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", user)
        expect(response.status).to eq(403)
      end

      it "should allow project to be forked from an existing project" do
        expect(project_fork_target.forked?).not_to be_true
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        expect(response.status).to eq(201)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked_project_link).not_to be_nil
        expect(project_fork_target.forked?).to be_true
      end

      it "should fail if forked_from project which does not exist" do
        post api("/projects/#{project_fork_target.id}/fork/9999", admin)
        expect(response.status).to eq(404)
      end

      it "should fail with 409 if already forked" do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        post api("/projects/#{project_fork_target.id}/fork/#{new_project_fork_source.id}", admin)
        expect(response.status).to eq(409)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project.id).to eq(project_fork_source.id)
        expect(project_fork_target.forked?).to be_true
      end
    end

    describe "DELETE /projects/:id/fork" do

      it "shouldn't available for non admin users" do
        delete api("/projects/#{project_fork_target.id}/fork", user)
        expect(response.status).to eq(403)
      end

      it "should make forked project unforked" do
        post api("/projects/#{project_fork_target.id}/fork/#{project_fork_source.id}", admin)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project).not_to be_nil
        expect(project_fork_target.forked?).to be_true
        delete api("/projects/#{project_fork_target.id}/fork", admin)
        expect(response.status).to eq(200)
        project_fork_target.reload
        expect(project_fork_target.forked_from_project).to be_nil
        expect(project_fork_target.forked?).not_to be_true
      end

      it "should be idempotent if not forked" do
        expect(project_fork_target.forked_from_project).to be_nil
        delete api("/projects/#{project_fork_target.id}/fork", admin)
        expect(response.status).to eq(200)
        expect(project_fork_target.reload.forked_from_project).to be_nil
      end
    end
  end

  describe "GET /projects/search/:query" do
    let!(:query) { 'query'}
    let!(:search)           { create(:empty_project, name: query, creator_id: user.id, namespace: user.namespace) }
    let!(:pre)              { create(:empty_project, name: "pre_#{query}", creator_id: user.id, namespace: user.namespace) }
    let!(:post)             { create(:empty_project, name: "#{query}_post", creator_id: user.id, namespace: user.namespace) }
    let!(:pre_post)         { create(:empty_project, name: "pre_#{query}_post", creator_id: user.id, namespace: user.namespace) }
    let!(:unfound)          { create(:empty_project, name: 'unfound', creator_id: user.id, namespace: user.namespace) }
    let!(:internal)         { create(:empty_project, :internal, name: "internal #{query}") }
    let!(:unfound_internal) { create(:empty_project, :internal, name: 'unfound internal') }
    let!(:public)           { create(:empty_project, :public, name: "public #{query}") }
    let!(:unfound_public)   { create(:empty_project, :public, name: 'unfound public') }

    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/search/#{query}")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return an array of projects" do
        get api("/projects/search/#{query}",user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(6)
        json_response.each {|project| expect(project['name']).to match(/.*query.*/)}
      end
    end

    context "when authenticated as a different user" do
      it "should return matching public projects" do
        get api("/projects/search/#{query}", user2)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(2)
        json_response.each {|project| expect(project['name']).to match(/(internal|public) query/)}
      end
    end
  end

  describe "DELETE /projects/:id" do
    context "when authenticated as user" do
      it "should remove project" do
        expect(GitlabShellWorker).to(
          receive(:perform_async).with(:remove_repository,
                                       /#{project.path_with_namespace}/)
        ).twice

        delete api("/projects/#{project.id}", user)
        expect(response.status).to eq(200)
      end

      it "should not remove a project if not an owner" do
        user3 = create(:user)
        project.team << [user3, :developer]
        delete api("/projects/#{project.id}", user3)
        expect(response.status).to eq(403)
      end

      it "should not remove a non existing project" do
        delete api("/projects/1328", user)
        expect(response.status).to eq(404)
      end

      it "should not remove a project not attached to user" do
        delete api("/projects/#{project.id}", user2)
        expect(response.status).to eq(404)
      end
    end

    context "when authenticated as admin" do
      it "should remove any existing project" do
        delete api("/projects/#{project.id}", admin)
        expect(response.status).to eq(200)
      end

      it "should not remove a non existing project" do
        delete api("/projects/1328", admin)
        expect(response.status).to eq(404)
      end
    end
  end
end
