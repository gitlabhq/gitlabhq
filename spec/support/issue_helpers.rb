module IssueHelpers
  def visit_issues(project, opts = {})
    visit namespace_project_issues_path project.namespace, project, opts
  end

  def first_issue
    page.all('ul.issues-list > li').first.text
  end

  def last_issue
    page.all('ul.issues-list > li').last.text
  end
end
