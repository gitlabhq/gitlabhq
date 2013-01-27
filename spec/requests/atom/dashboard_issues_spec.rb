require 'spec_helper'

describe "Dashboard Issues Feed" do
  describe "GET /issues" do
    let!(:user)     { create(:user) }
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project) }
    let!(:issue1)   { create(:issue, author: user, assignee: user, project: project1) }
    let!(:issue2)   { create(:issue, author: user, assignee: user, project: project2) }

    describe "atom feed" do
      it "should render atom feed via private token" do
        visit issues_dashboard_path(:atom, private_token: user.private_token)

        page.response_headers['Content-Type'].should have_content("application/atom+xml")
        page.body.should have_selector("title", text: "#{user.name} issues")
        page.body.should have_selector("author email", text: issue1.author_email)
        page.body.should have_selector("entry summary", text: issue1.title)
        page.body.should have_selector("author email", text: issue2.author_email)
        page.body.should have_selector("entry summary", text: issue2.title)
      end
    end
  end
end
