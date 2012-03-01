shared_examples_for :project_side_pane do
  subject { page }
  it { should have_content((@project || project).name) }
  it { should have_content("Commits") }
  it { should have_content("Files") }
end

shared_examples_for :tree_view do
  subject { page }

  it "should have Tree View of project" do
    should have_content("app")
    should have_content("History")
    should have_content("Gemfile")
  end
end
