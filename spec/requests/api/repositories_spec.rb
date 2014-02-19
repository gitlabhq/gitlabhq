require 'spec_helper'
require 'mime/types'

describe API::API do
  include ApiHelpers
  before(:each) { enable_observers }
  after(:each) {disable_observers}

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:guest) { create(:users_project, user: user2, project: project, project_access: UsersProject::GUEST) }

  before { project.team << [user, :reporter] }


  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      get api("/projects/#{project.id}/repository/branches", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.heads.sort_by(&:name).first.name
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get api("/projects/#{project.id}/repository/branches/new_design", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == false
    end

    it "should return a 403 error if guest" do
      get api("/projects/#{project.id}/repository/branches", user2)
      response.status.should == 403
    end

    it "should return a 404 error if branch is not available" do
      get api("/projects/#{project.id}/repository/branches/unknown", user)
      response.status.should == 404
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/protect" do
    it "should protect a single branch" do
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == true
    end

    it "should return a 404 error if branch not found" do
      put api("/projects/#{project.id}/repository/branches/unknown/protect", user)
      response.status.should == 404
    end

    it "should return a 403 error if guest" do
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user2)
      response.status.should == 403
    end

    it "should return success when protect branch again" do
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      put api("/projects/#{project.id}/repository/branches/new_design/protect", user)
      response.status.should == 200
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/unprotect" do
    it "should unprotect a single branch" do
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
      json_response['protected'].should == false
    end

    it "should return success when unprotect branch" do
      put api("/projects/#{project.id}/repository/branches/unknown/unprotect", user)
      response.status.should == 404
    end

    it "should return success when unprotect branch again" do
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      put api("/projects/#{project.id}/repository/branches/new_design/unprotect", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.id}/repository/tags", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
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
end
