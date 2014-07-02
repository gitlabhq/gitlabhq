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
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
    end
  end

  describe 'POST /projects/:id/repository/tags' do
    it 'should create a new tag' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v1.0.0',
           ref: 'master'

      response.status.should == 201
      json_response['name'].should == 'v1.0.0'
    end
    it 'should deny for user without push access' do
      post api("/projects/#{project.id}/repository/tags", user2),
           tag_name: 'v1.0.0',
           ref: '621491c677087aa243f165eab467bfdfbee00be1'

      response.status.should == 403
    end
  end

  describe "GET /projects/:id/repository/tree" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/tree", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['name'].should == 'app'
        json_response.first['type'].should == 'tree'
        json_response.first['mode'].should == '040000'
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/tree")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects/:id/repository/blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.md", user)
      response.status.should == 200
    end

    it "should return 404 for invalid branch_name" do
      get api("/projects/#{project.id}/repository/blobs/invalid_branch_name?filepath=README.md", user)
      response.status.should == 404
    end

    it "should return 404 for invalid file" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.invalid", user)
      response.status.should == 404
    end

    it "should return a 400 error if filepath is missing" do
      get api("/projects/#{project.id}/repository/blobs/master", user)
      response.status.should == 400
    end
  end

  describe "GET /projects/:id/repository/commits/:sha/blob" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/commits/master/blob?filepath=README.md", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/repository/raw_blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/raw_blobs/d1aff2896d99d7acc4d9780fbb716b113c45ecf7", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    it "should get the archive" do
      get api("/projects/#{project.id}/repository/archive", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.tar.gz\"/
      response.content_type.should == MIME::Types.type_for('file.tar.gz').first.content_type
    end

    it "should get the archive.zip" do
      get api("/projects/#{project.id}/repository/archive.zip", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.zip\"/
      response.content_type.should == MIME::Types.type_for('file.zip').first.content_type
    end

    it "should get the archive.tar.bz2" do
      get api("/projects/#{project.id}/repository/archive.tar.bz2", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.tar.bz2\"/
      response.content_type.should == MIME::Types.type_for('file.tar.bz2').first.content_type
    end

    it "should return 404 for invalid sha" do
      get api("/projects/#{project.id}/repository/archive/?sha=xxx", user)
      response.status.should == 404
    end
  end

  describe 'GET /projects/:id/repository/compare' do
    it "should compare branches" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'simple_merge_request'
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare tags" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'v1.0.1', to: 'v1.0.2'
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare commits" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'b1e6a9dbf1c85', to: '1e689bfba395'
      response.status.should == 200
      json_response['commits'].should be_empty
      json_response['diffs'].should be_empty
      json_response['compare_same_ref'].should be_false
    end

    it "should compare commits in reverse order" do
      get api("/projects/#{project.id}/repository/compare", user), from: '1e689bfba395', to: 'b1e6a9dbf1c85'
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare same refs" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'master'
      response.status.should == 200
      json_response['commits'].should be_empty
      json_response['diffs'].should be_empty
      json_response['compare_same_ref'].should be_true
    end
  end

  describe 'GET /projects/:id/repository/contributors' do
    it 'should return valid data' do
      get api("/projects/#{project.id}/repository/contributors", user)
      response.status.should == 200
      json_response.should be_an Array
      contributor = json_response.first
      contributor['email'].should == 'dmitriy.zaporozhets@gmail.com'
      contributor['name'].should == 'Dmitriy Zaporozhets'
      contributor['commits'].should == 185
      contributor['additions'].should == 66072
      contributor['deletions'].should == 63013
    end
  end
end
