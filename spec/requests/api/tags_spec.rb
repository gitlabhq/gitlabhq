require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  include RepoHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }

  describe "GET /projects/:id/repository/tags" do
    let(:tag_name) { project.repository.tag_names.sort.reverse.first }
    let(:description) { 'Awesome release!' }

    context 'without releases' do
      it "returns an array of project tags" do
        get api("/projects/#{project.id}/repository/tags", user)
        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(tag_name)
      end
    end

    context 'with releases' do
      before do
        release = project.releases.find_or_initialize_by(tag: tag_name)
        release.update_attributes(description: description)
      end

      it "returns an array of project tags with release info" do
        get api("/projects/#{project.id}/repository/tags", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(tag_name)
        expect(json_response.first['message']).to eq('Version 1.1.0')
        expect(json_response.first['release']['description']).to eq(description)
      end
    end
  end

  describe 'GET /projects/:id/repository/tags/:tag_name' do
    let(:tag_name) { project.repository.tag_names.sort.reverse.first }

    it 'returns a specific tag' do
      get api("/projects/#{project.id}/repository/tags/#{tag_name}", user)

      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq(tag_name)
    end

    it 'returns 404 for an invalid tag name' do
      get api("/projects/#{project.id}/repository/tags/foobar", user)

      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /projects/:id/repository/tags' do
    context 'lightweight tags' do
      it 'creates a new tag' do
        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.0.1',
             ref: 'master'

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq('v7.0.1')
      end
    end

    context 'lightweight tags with release notes' do
      it 'creates a new tag' do
        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.0.1',
             ref: 'master',
             release_description: 'Wow'

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq('v7.0.1')
        expect(json_response['release']['description']).to eq('Wow')
      end
    end

    describe 'DELETE /projects/:id/repository/tags/:tag_name' do
      let(:tag_name) { project.repository.tag_names.sort.reverse.first }

      before do
        allow_any_instance_of(Repository).to receive(:rm_tag).and_return(true)
      end

      context 'delete tag' do
        it 'deletes an existing tag' do
          delete api("/projects/#{project.id}/repository/tags/#{tag_name}", user)
          expect(response).to have_http_status(200)
          expect(json_response['tag_name']).to eq(tag_name)
        end

        it 'raises 404 if the tag does not exist' do
          delete api("/projects/#{project.id}/repository/tags/foobar", user)
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'annotated tag' do
      it 'creates a new annotated tag' do
        # Identity must be set in .gitconfig to create annotated tag.
        repo_path = project.repository.path_to_repo
        system(*%W[#{Gitlab.config.git.bin_path} --git-dir=#{repo_path} config user.name #{user.name}])
        system(*%W[#{Gitlab.config.git.bin_path} --git-dir=#{repo_path} config user.email #{user.email}])

        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.1.0',
             ref: 'master',
             message: 'Release 7.1.0'

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq('v7.1.0')
        expect(json_response['message']).to eq('Release 7.1.0')
      end
    end

    it 'denies for user without push access' do
      post api("/projects/#{project.id}/repository/tags", user2),
           tag_name: 'v1.9.0',
           ref: '621491c677087aa243f165eab467bfdfbee00be1'
      expect(response).to have_http_status(403)
    end

    it 'returns 400 if tag name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v 1.0.0',
           ref: 'master'
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Tag name invalid')
    end

    it 'returns 400 if tag already exists' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      expect(response).to have_http_status(201)
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Tag v8.0.0 already exists')
    end

    it 'returns 400 if ref name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'mytag',
           ref: 'foo'
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Target foo is invalid')
    end
  end

  describe 'POST /projects/:id/repository/tags/:tag_name/release' do
    let(:tag_name) { project.repository.tag_names.first }
    let(:description) { 'Awesome release!' }

    it 'creates description for existing git tag' do
      post api("/projects/#{project.id}/repository/tags/#{tag_name}/release", user),
        description: description

      expect(response).to have_http_status(201)
      expect(json_response['tag_name']).to eq(tag_name)
      expect(json_response['description']).to eq(description)
    end

    it 'returns 404 if the tag does not exist' do
      post api("/projects/#{project.id}/repository/tags/foobar/release", user),
        description: description

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('Tag does not exist')
    end

    context 'on tag with existing release' do
      before do
        release = project.releases.find_or_initialize_by(tag: tag_name)
        release.update_attributes(description: description)
      end

      it 'returns 409 if there is already a release' do
        post api("/projects/#{project.id}/repository/tags/#{tag_name}/release", user),
          description: description

        expect(response).to have_http_status(409)
        expect(json_response['message']).to eq('Release already exists')
      end
    end
  end

  describe 'PUT id/repository/tags/:tag_name/release' do
    let(:tag_name) { project.repository.tag_names.first }
    let(:description) { 'Awesome release!' }
    let(:new_description) { 'The best release!' }

    context 'on tag with existing release' do
      before do
        release = project.releases.find_or_initialize_by(tag: tag_name)
        release.update_attributes(description: description)
      end

      it 'updates the release description' do
        put api("/projects/#{project.id}/repository/tags/#{tag_name}/release", user),
          description: new_description

        expect(response).to have_http_status(200)
        expect(json_response['tag_name']).to eq(tag_name)
        expect(json_response['description']).to eq(new_description)
      end
    end

    it 'returns 404 if the tag does not exist' do
      put api("/projects/#{project.id}/repository/tags/foobar/release", user),
        description: new_description

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('Tag does not exist')
    end

    it 'returns 404 if the release does not exist' do
      put api("/projects/#{project.id}/repository/tags/#{tag_name}/release", user),
        description: new_description

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('Release does not exist')
    end
  end
end
