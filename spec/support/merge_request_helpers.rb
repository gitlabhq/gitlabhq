module MergeRequestHelpers
  def visit_merge_requests(project, opts = {})
    visit namespace_project_merge_requests_path project.namespace, project, opts
  end

  def first_merge_request
    page.all('ul.mr-list > li').first.text
  end

  def last_merge_request
    page.all('ul.mr-list > li').last.text
  end
end
