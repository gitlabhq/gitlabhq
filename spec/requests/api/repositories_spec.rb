require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  include RepoHelpers
  include WorkhorseHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }

  describe "GET /projects/:id/repository/tree" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/tree", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq('encoding')
        expect(json_response.first['type']).to eq('tree')
        expect(json_response.first['mode']).to eq('040000')
      end

      it 'should return a 404 for unknown ref' do
        get api("/projects/#{project.id}/repository/tree?ref_name=foo", user)
        expect(response.status).to eq(404)

        expect(json_response).to be_an Object
        json_response['message'] == '404 Tree Not Found'
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
      get api("/projects/#{project.id}/repository/raw_blobs/#{sample_blob.oid}", user)
      expect(response.status).to eq(200)
    end

    it 'should return a 404 for unknown blob' do
      get api("/projects/#{project.id}/repository/raw_blobs/123456", user)
      expect(response.status).to eq(404)

      expect(json_response).to be_an Object
      json_response['message'] == '404 Blob Not Found'
    end
  end

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    it "should get the archive" do
      get api("/projects/#{project.id}/repository/archive", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      type, params = workhorse_send_data
      expect(type).to eq('git-archive')
      expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.tar.gz/)
    end

    it "should get the archive.zip" do
      get api("/projects/#{project.id}/repository/archive.zip", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      type, params = workhorse_send_data
      expect(type).to eq('git-archive')
      expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.zip/)
    end

    it "should get the archive.tar.bz2" do
      get api("/projects/#{project.id}/repository/archive.tar.bz2", user)
      repo_name = project.repository.name.gsub("\.git", "")
      expect(response.status).to eq(200)
      type, params = workhorse_send_data
      expect(type).to eq('git-archive')
      expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.tar.bz2/)
    end

    it "should return 404 for invalid sha" do
      get api("/projects/#{project.id}/repository/archive/?sha=xxx", user)
      expect(response.status).to eq(404)
    end
  end

  describe 'GET /projects/:id/repository/compare' do
    it "should compare branches" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'feature'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare tags" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'v1.0.0', to: 'v1.1.0'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare commits" do
      get api("/projects/#{project.id}/repository/compare", user), from: sample_commit.id, to: sample_commit.parent_id
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_empty
      expect(json_response['diffs']).to be_empty
      expect(json_response['compare_same_ref']).to be_falsey
    end

    it "should compare commits in reverse order" do
      get api("/projects/#{project.id}/repository/compare", user), from: sample_commit.parent_id, to: sample_commit.id
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_present
      expect(json_response['diffs']).to be_present
    end

    it "should compare same refs" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'master'
      expect(response.status).to eq(200)
      expect(json_response['commits']).to be_empty
      expect(json_response['diffs']).to be_empty
      expect(json_response['compare_same_ref']).to be_truthy
    end
  end

  describe 'GET /projects/:id/repository/contributors' do
    it 'should return valid data' do
      get api("/projects/#{project.id}/repository/contributors", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      contributor = json_response.first
      expect(contributor['email']).to eq('dmitriy.zaporozhets@gmail.com')
      expect(contributor['name']).to eq('Dmitriy Zaporozhets')
      expect(contributor['commits']).to eq(13)
      expect(contributor['additions']).to eq(0)
      expect(contributor['deletions']).to eq(0)
    end
  end
end
