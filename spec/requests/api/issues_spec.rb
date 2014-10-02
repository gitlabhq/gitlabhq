require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:closed_issue) do
    create :closed_issue,
           author: user,
           assignee: user,
           project: project,
           state: :closed,
           milestone: milestone
  end
  let!(:issue) do
    create :issue,
           author: user,
           assignee: user,
           project: project,
           milestone: milestone
  end
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let!(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let!(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end

  before { project.team << [user, :reporter] }

  describe "GET /issues" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/issues")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of issues" do
        get api("/issues", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['title'].should == issue.title
      end

      it "should add pagination headers" do
        get api("/issues?per_page=3", user)
        response.headers['Link'].should ==
          '<http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="first", <http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="last"'
      end

      it 'should return an array of closed issues' do
        get api('/issues?state=closed', user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['id'].should == closed_issue.id
      end

      it 'should return an array of opened issues' do
        get api('/issues?state=opened', user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['id'].should == issue.id
      end

      it 'should return an array of all issues' do
        get api('/issues?state=all', user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
        json_response.first['id'].should == issue.id
        json_response.second['id'].should == closed_issue.id
      end

      it 'should return an array of labeled issues' do
        get api("/issues?labels=#{label.title}", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['labels'].should == [label.title]
      end

      it 'should return an array of labeled issues when at least one label matches' do
        get api("/issues?labels=#{label.title},foo,bar", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['labels'].should == [label.title]
      end

      it 'should return an empty array if no issue matches labels' do
        get api('/issues?labels=foo,bar', user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 0
      end

      it 'should return an array of labeled issues matching given state' do
        get api("/issues?labels=#{label.title}&state=opened", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['labels'].should == [label.title]
        json_response.first['state'].should == 'opened'
      end

      it 'should return an empty array if no issue matches labels and state filters' do
        get api("/issues?labels=#{label.title}&state=closed", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 0
      end
    end
  end

  describe "GET /projects/:id/issues" do
    let(:base_url) { "/projects/#{project.id}" }
    let(:title) { milestone.title }

    it "should return project issues" do
      get api("#{base_url}/issues", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == issue.title
    end

    it 'should return an array of labeled project issues' do
      get api("#{base_url}/issues?labels=#{label.title}", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 1
      json_response.first['labels'].should == [label.title]
    end

    it 'should return an array of labeled project issues when at least one label matches' do
      get api("#{base_url}/issues?labels=#{label.title},foo,bar", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 1
      json_response.first['labels'].should == [label.title]
    end

    it 'should return an empty array if no project issue matches labels' do
      get api("#{base_url}/issues?labels=foo,bar", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 0
    end

    it 'should return an empty array if no issue matches milestone' do
      get api("#{base_url}/issues?milestone=#{empty_milestone.title}", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 0
    end

    it 'should return an empty array if milestone does not exist' do
      get api("#{base_url}/issues?milestone=foo", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 0
    end

    it 'should return an array of issues in given milestone' do
      get api("#{base_url}/issues?milestone=#{title}", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 2
      json_response.first['id'].should == issue.id
      json_response.second['id'].should == closed_issue.id
    end

    it 'should return an array of issues matching state in milestone' do
      get api("#{base_url}/issues?milestone=#{milestone.title}"\
              '&state=closed', user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.length.should == 1
      json_response.first['id'].should == closed_issue.id
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it "should return a project issue by id" do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)
      response.status.should == 200
      json_response['title'].should == issue.title
      json_response['iid'].should == issue.iid
    end

    it "should return 404 if issue id not found" do
      get api("/projects/#{project.id}/issues/54321", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/issues" do
    it "should create a new project issue" do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2'
      response.status.should == 201
      json_response['title'].should == 'new issue'
      json_response['description'].should be_nil
      json_response['labels'].should == ['label', 'label2']
    end

    it "should return a 400 bad request if title not given" do
      post api("/projects/#{project.id}/issues", user), labels: 'label, label2'
      response.status.should == 400
    end

    it 'should return 400 on invalid label names' do
      post api("/projects/#{project.id}/issues", user),
           title: 'new issue',
           labels: 'label, ?'
      response.status.should == 400
      json_response['message']['labels']['?']['title'].should == ['is invalid']
    end

    it 'should return 400 if title is too long' do
      post api("/projects/#{project.id}/issues", user),
           title: 'g' * 256
      response.status.should == 400
      json_response['message']['title'].should == [
        'is too long (maximum is 255 characters)'
      ]
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update only title" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        title: 'updated title'
      response.status.should == 200

      json_response['title'].should == 'updated title'
    end

    it "should return 404 error if issue id not found" do
      put api("/projects/#{project.id}/issues/44444", user),
        title: 'updated title'
      response.status.should == 404
    end

    it 'should return 400 on invalid label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title',
          labels: 'label, ?'
      response.status.should == 400
      json_response['message']['labels']['?']['title'].should == ['is invalid']
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'should not update labels if not present' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title'
      response.status.should == 200
      json_response['labels'].should == [label.title]
    end

    it 'should remove all labels' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: ''
      response.status.should == 200
      json_response['labels'].should == []
    end

    it 'should update labels' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'foo,bar'
      response.status.should == 200
      json_response['labels'].should include 'foo'
      json_response['labels'].should include 'bar'
    end

    it 'should return 400 on invalid label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label, ?'
      response.status.should == 400
      json_response['message']['labels']['?']['title'].should == ['is invalid']
    end

    it 'should allow special label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label:foo, label-bar,label_bar,label/bar'
      response.status.should == 200
      json_response['labels'].should include 'label:foo'
      json_response['labels'].should include 'label-bar'
      json_response['labels'].should include 'label_bar'
      json_response['labels'].should include 'label/bar'
    end

    it 'should return 400 if title is too long' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'g' * 256
      response.status.should == 400
      json_response['message']['title'].should == [
        'is too long (maximum is 255 characters)'
      ]
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update state and label" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        labels: 'label2', state_event: "close"
      response.status.should == 200

      json_response['labels'].should include 'label2'
      json_response['state'].should eq "closed"
    end
  end

  describe "DELETE /projects/:id/issues/:issue_id" do
    it "should delete a project issue" do
      delete api("/projects/#{project.id}/issues/#{issue.id}", user)
      response.status.should == 405
    end
  end
end
