require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:guest) { create(:users_project, user: user2, project: project, project_access: UsersProject::GUEST) }

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.id}/repository/tags", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).to eq(project.repo.tags.sort_by(&:name).reverse.first.name)
    end
  end

  describe 'POST /projects/:id/repository/tags' do
    it 'should create a new tag' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v1.0.0',
           ref: 'master'

      expect(response.status).to eq(201)
      expect(json_response['name']).to eq('v1.0.0')
    end
    it 'should deny for user without push access' do
      post api("/projects/#{project.id}/repository/tags", user2),
           tag_name: 'v1.0.0',
           ref: '621491c677087aa243f165eab467bfdfbee00be1'

      expect(response.status).to eq(403)
    end
  end

  describe "GET /projects/:id/repository/tree" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/tree", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq('app')
        expect(json_response.first['type']).to eq('tree')
        expect(json_response.first['mode']).to eq('040000')
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/tree")
        expect(response.status).to eq(401)
      end
    end
  end

  describe "GET /projects/:id/repository/blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.md", user)
      expect(response.status).to eq(200)
    end

    it "should return 404 for invalid branch_name" do
      get api("/projects/#{project.id}/repository/blobs/invalid_branch_name?filepath=README.md", user)
      expect(response.status).to eq(404)
    end

    it "should return 404 for invalid file" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.invalid", user)
      expect(response.status).to eq(404)
    end

    it "should return a 400 error if filepath is missing" do
      get api("/projects/#{project.id}/repository/blobs/master", user)
      expect(response.status).to eq(400)
    end
  end

  describe "GET /projects/:id/repository/commits/:sha/blob" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/commits/master/blob?filepath=README.md", user)
      expect(response.status).to eq(200)
    end
  end

  describe "GET /projects/:id/repository/raw_blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/raw_blobs/d1aff2896d99d7acc4d9780fbb716b113c45ecf7", user)
      expect(response.status).to eq(200)
    end
  end

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    it "should get the archive" do
      get api("/projects/#{project.id}/repository/archive", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      expect(response.headers['Content-Disposition']).to match(/filename\=\"#{repo_name}\-[^\.]+\.tar.gz\"/)
      expect(response.content_type).to eq(MIME::Types.type_for('file.tar.gz').first.content_type)
    end

    it "should get the archive.zip" do
      get api("/projects/#{project.id}/repository/archive.zip", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      expect(response.headers['Content-Disposition']).to match(/filename\=\"#{repo_name}\-[^\.]+\.zip\"/)
      expect(response.content_type).to eq(MIME::Types.type_for('file.zip').first.content_type)
    end

    it "should get the archive.tar.bz2" do
      get api("/projects/#{project.id}/repository/archive.tar.bz2", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      expect(response.headers['Content-Disposition']).to match(/filename\=\"#{repo_name}\-[^\.]+\.tar.bz2\"/)
      expect(response.content_type).to eq(MIME::Types.type_for('file.tar.bz2').first.content_type)
    end

    it "should return 404 for invalid sha" do
      get api("/projects/#{project.id}/repository/archive/?sha=xxx", user)
      expect(response.status).to eq(404)
    end
  end

  describe 'GET /GET /projects/:id/repository/compare' do
    it "should compare branches" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'simple_merge_request'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare tags" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'v1.0.1', to: 'v1.0.2'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare commits" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'b1e6a9dbf1c85', to: '1e689bfba395'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_empty
      expect(json_response['diffs']).to be_empty
      expect(json_response['compare_same_ref']).to be_false
    end

    it "should compare commits in reverse order" do
      get api("/projects/#{project.id}/repository/compare", user), from: '1e689bfba395', to: 'b1e6a9dbf1c85'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare same refs" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'master'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_empty
      expect(json_response['diffs']).to be_empty
      expect(json_response['compare_same_ref']).to be_true
    end
  end
end
