require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let!(:project) { create(:project, owner: user) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:snippet) { create(:snippet, project: project, author: user) }
  let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }
  let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }
  let!(:wall_note) { create(:note, project: project, author: user) }
  before { project.add_access(user, :read) }

  describe "GET /projects/:id/notes" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects/#{project.id}/notes")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return project wall notes" do
        get api("/projects/#{project.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == wall_note.note
      end
    end
  end

  describe "GET /projects/:id/noteable/:noteable_id/notes" do
    context "when noteable is an Issue" do
      it "should return an array of notes" do
        get api("/projects/#{project.id}/issues/#{issue.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == issue_note.note
      end
    end

    context "when noteable is a Snippet" do
      it "should return an array of notes" do
        get api("/projects/#{project.id}/snippets/#{snippet.id}/notes", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['body'].should == snippet_note.note
      end
    end
  end
end
