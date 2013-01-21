require 'spec_helper'

describe "Gitlab Flavored Markdown" do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, project: project) }
  let(:fred) do
      u = create(:user, name: "fred")
      project.team << [u, :master]
      u
  end

  before do
    # add test branch
    @branch_name = "gfm-test"
    r = project.repo
    i = r.index
    # add test file
    @test_file = "gfm_test_file"
    i.add(@test_file, "foo\nbar\n")
    # add commit with gfm
    i.commit("fix ##{issue.id}\n\nask @#{fred.username} for details", head: @branch_name)

    # add test tag
    @tag_name = "gfm-test-tag"
    r.git.native(:tag, {}, @tag_name, commit.id)
  end

  after do
    # delete test branch and tag
    project.repo.git.native(:branch, {D: true}, @branch_name)
    project.repo.git.native(:tag, {d: true}, @tag_name)
    project.repo.gc_auto
  end

  let(:commit) { project.repository.commits(@branch_name).first }

  before do
    login_as :user
    project.team << [@user, :developer]
  end

  describe "for commits" do
    it "should render title in commits#index" do
      visit project_commits_path(project, @branch_name, limit: 1)

      page.should have_link("##{issue.id}")
    end

    it "should render title in commits#show" do
      visit project_commit_path(project, commit)

      page.should have_link("##{issue.id}")
    end

    it "should render description in commits#show" do
      visit project_commit_path(project, commit)

      page.should have_link("@#{fred.username}")
    end

    it "should render title in refs#tree", js: true do
      visit project_tree_path(project, @branch_name)

      within(".tree_commit") do
        page.should have_link("##{issue.id}")
      end
    end

    # @wip
    #it "should render title in refs#blame" do
      #visit project_blame_path(project, File.join(@branch_name, @test_file))

      #within(".blame_commit") do
        #page.should have_link("##{issue.id}")
      #end
    #end

    it "should render title in repositories#branches" do
      visit branches_project_repository_path(project)

      page.should have_link("##{issue.id}")
    end
  end

  describe "for issues" do
    before do
      @other_issue = create(:issue,
                            author: @user,
                            assignee: @user,
                            project: project)
      @issue = create(:issue,
                      author: @user,
                      assignee: @user,
                      project: project,
                      title: "fix ##{@other_issue.id}",
                      description: "ask @#{fred.username} for details")
    end

    it "should render subject in issues#index" do
      visit project_issues_path(project)

      page.should have_link("##{@other_issue.id}")
    end

    it "should render subject in issues#show" do
      visit project_issue_path(project, @issue)

      page.should have_link("##{@other_issue.id}")
    end

    it "should render details in issues#show" do
      visit project_issue_path(project, @issue)

      page.should have_link("@#{fred.username}")
    end
  end


  describe "for merge requests" do
    before do
      @merge_request = create(:merge_request,
                              project: project,
                              title: "fix ##{issue.id}")
    end

    it "should render title in merge_requests#index" do
      visit project_merge_requests_path(project)

      page.should have_link("##{issue.id}")
    end

    it "should render title in merge_requests#show" do
      visit project_merge_request_path(project, @merge_request)

      page.should have_link("##{issue.id}")
    end
  end


  describe "for milestones" do
    before do
      @milestone = create(:milestone,
                          project: project,
                          title: "fix ##{issue.id}",
                          description: "ask @#{fred.username} for details")
    end

    it "should render title in milestones#index" do
      visit project_milestones_path(project)

      page.should have_link("##{issue.id}")
    end

    it "should render title in milestones#show" do
      visit project_milestone_path(project, @milestone)

      page.should have_link("##{issue.id}")
    end

    it "should render description in milestones#show" do
      visit project_milestone_path(project, @milestone)

      page.should have_link("@#{fred.username}")
    end
  end


  describe "for notes" do
    it "should render in commits#show", js: true do
      visit project_commit_path(project, commit)
      fill_in "note_note", with: "see ##{issue.id}"
      click_button "Add Comment"

      page.should have_link("##{issue.id}")
    end

    it "should render in issue#show", js: true do
      visit project_issue_path(project, issue)
      fill_in "note_note", with: "see ##{issue.id}"
      click_button "Add Comment"

      page.should have_link("##{issue.id}")
    end

    it "should render in merge_request#show", js: true do
      visit project_merge_request_path(project, merge_request)
      fill_in "note_note", with: "see ##{issue.id}"
      click_button "Add Comment"

      page.should have_link("##{issue.id}")
    end

    it "should render in projects#wall", js: true do
      visit wall_project_path(project)
      fill_in "note_note", with: "see ##{issue.id}"
      click_button "Add Comment"

      page.should have_link("##{issue.id}")
    end
  end


  describe "for wikis" do
    before do
      visit project_wiki_path(project, :index)
      fill_in "Title", with: "Circumvent ##{issue.id}"
      fill_in "Content", with: "# Other pages\n\n* [Foo](foo)\n* [Bar](bar)\n\nAlso look at ##{issue.id} :-)"
      click_on "Save"
    end

    it "should NOT render title in wikis#show" do
      within(".content h3") do # page title
        page.should have_content("Circumvent ##{issue.id}")
        page.should_not have_link("##{issue.id}")
      end
    end

    it "should render content in wikis#show" do
      page.should have_link("##{issue.id}")
    end
  end
end
