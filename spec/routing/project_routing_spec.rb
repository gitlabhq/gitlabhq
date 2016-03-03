require 'spec_helper'

# Shared examples for a resource inside a Project
#
# By default it tests all the default REST actions: index, create, new, edit,
# show, update, and destroy. You can remove actions by customizing the
# `actions` variable.
#
# It also expects a `controller` variable to be available which defines both
# the path to the resource as well as the controller name.
#
# Examples
#
#   # Default behavior
#   it_behaves_like 'RESTful project resources' do
#     let(:controller) { 'issues' }
#   end
#
#   # Customizing actions
#   it_behaves_like 'RESTful project resources' do
#     let(:actions)    { [:index] }
#     let(:controller) { 'issues' }
#   end
shared_examples 'RESTful project resources' do
  let(:actions) { [:index, :create, :new, :edit, :show, :update, :destroy] }

  it 'to #index' do
    expect(get("/gitlab/gitlabhq/#{controller}")).to route_to("projects/#{controller}#index", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:index)
  end

  it 'to #create' do
    expect(post("/gitlab/gitlabhq/#{controller}")).to route_to("projects/#{controller}#create", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:create)
  end

  it 'to #new' do
    expect(get("/gitlab/gitlabhq/#{controller}/new")).to route_to("projects/#{controller}#new", namespace_id: 'gitlab', project_id: 'gitlabhq') if actions.include?(:new)
  end

  it 'to #edit' do
    expect(get("/gitlab/gitlabhq/#{controller}/1/edit")).to route_to("projects/#{controller}#edit", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:edit)
  end

  it 'to #show' do
    expect(get("/gitlab/gitlabhq/#{controller}/1")).to route_to("projects/#{controller}#show", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:show)
  end

  it 'to #update' do
    expect(put("/gitlab/gitlabhq/#{controller}/1")).to route_to("projects/#{controller}#update", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:update)
  end

  it 'to #destroy' do
    expect(delete("/gitlab/gitlabhq/#{controller}/1")).to route_to("projects/#{controller}#destroy", namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1') if actions.include?(:destroy)
  end
end

#                 projects POST   /projects(.:format)     projects#create
#              new_project GET    /projects/new(.:format) projects#new
#            files_project GET    /:id/files(.:format)    projects#files
#             edit_project GET    /:id/edit(.:format)     projects#edit
#                  project GET    /:id(.:format)          projects#show
#                          PUT    /:id(.:format)          projects#update
#                          DELETE /:id(.:format)          projects#destroy
# markdown_preview_project POST   /:id/markdown_preview(.:format) projects#markdown_preview
describe ProjectsController, 'routing' do
  it 'to #create' do
    expect(post('/projects')).to route_to('projects#create')
  end

  it 'to #new' do
    expect(get('/projects/new')).to route_to('projects#new')
  end

  it 'to #edit' do
    expect(get('/gitlab/gitlabhq/edit')).to route_to('projects#edit', namespace_id: 'gitlab', id: 'gitlabhq')
  end

  it 'to #autocomplete_sources' do
    expect(get('/gitlab/gitlabhq/autocomplete_sources')).to route_to('projects#autocomplete_sources', namespace_id: 'gitlab', id: 'gitlabhq')
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq')).to route_to('projects#show', namespace_id: 'gitlab', id: 'gitlabhq')
    expect(get('/gitlab/gitlabhq.keys')).to route_to('projects#show', namespace_id: 'gitlab', id: 'gitlabhq.keys')
  end

  it 'to #update' do
    expect(put('/gitlab/gitlabhq')).to route_to('projects#update', namespace_id: 'gitlab', id: 'gitlabhq')
  end

  it 'to #destroy' do
    expect(delete('/gitlab/gitlabhq')).to route_to('projects#destroy', namespace_id: 'gitlab', id: 'gitlabhq')
  end

  it 'to #markdown_preview' do
    expect(post('/gitlab/gitlabhq/markdown_preview')).to(
      route_to('projects#markdown_preview', namespace_id: 'gitlab', id: 'gitlabhq')
    )
  end
end

#  pages_project_wikis GET    /:project_id/wikis/pages(.:format)       projects/wikis#pages
# history_project_wiki GET    /:project_id/wikis/:id/history(.:format) projects/wikis#history
#        project_wikis POST   /:project_id/wikis(.:format)             projects/wikis#create
#    edit_project_wiki GET    /:project_id/wikis/:id/edit(.:format)    projects/wikis#edit
#         project_wiki GET    /:project_id/wikis/:id(.:format)         projects/wikis#show
#                      DELETE /:project_id/wikis/:id(.:format)         projects/wikis#destroy
describe Projects::WikisController, 'routing' do
  it 'to #pages' do
    expect(get('/gitlab/gitlabhq/wikis/pages')).to route_to('projects/wikis#pages', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #history' do
    expect(get('/gitlab/gitlabhq/wikis/1/history')).to route_to('projects/wikis#history', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:create, :edit, :show, :destroy] }
    let(:controller) { 'wikis' }
  end
end

# branches_project_repository GET    /:project_id/repository/branches(.:format) projects/repositories#branches
#     tags_project_repository GET    /:project_id/repository/tags(.:format)     projects/repositories#tags
#  archive_project_repository GET    /:project_id/repository/archive(.:format)  projects/repositories#archive
#     edit_project_repository GET    /:project_id/repository/edit(.:format)     projects/repositories#edit
describe Projects::RepositoriesController, 'routing' do
  it 'to #archive' do
    expect(get('/gitlab/gitlabhq/repository/archive')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #archive format:zip' do
    expect(get('/gitlab/gitlabhq/repository/archive.zip')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'zip')
  end

  it 'to #archive format:tar.bz2' do
    expect(get('/gitlab/gitlabhq/repository/archive.tar.bz2')).to route_to('projects/repositories#archive', namespace_id: 'gitlab', project_id: 'gitlabhq', format: 'tar.bz2')
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq/repository')).to route_to('projects/repositories#show', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end
end

describe Projects::BranchesController, 'routing' do
  it 'to #branches' do
    expect(get('/gitlab/gitlabhq/branches')).to route_to('projects/branches#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    expect(delete('/gitlab/gitlabhq/branches/feature%2345')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
    expect(delete('/gitlab/gitlabhq/branches/feature%2B45')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
    expect(delete('/gitlab/gitlabhq/branches/feature@45')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
    expect(delete('/gitlab/gitlabhq/branches/feature%2345/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45/foo/bar/baz')
    expect(delete('/gitlab/gitlabhq/branches/feature%2B45/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45/foo/bar/baz')
    expect(delete('/gitlab/gitlabhq/branches/feature@45/foo/bar/baz')).to route_to('projects/branches#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45/foo/bar/baz')
  end
end

describe Projects::TagsController, 'routing' do
  it 'to #tags' do
    expect(get('/gitlab/gitlabhq/tags')).to route_to('projects/tags#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    expect(delete('/gitlab/gitlabhq/tags/feature%2345')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
    expect(delete('/gitlab/gitlabhq/tags/feature%2B45')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
    expect(delete('/gitlab/gitlabhq/tags/feature@45')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
    expect(delete('/gitlab/gitlabhq/tags/feature%2345/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45/foo/bar/baz')
    expect(delete('/gitlab/gitlabhq/tags/feature%2B45/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45/foo/bar/baz')
    expect(delete('/gitlab/gitlabhq/tags/feature@45/foo/bar/baz')).to route_to('projects/tags#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45/foo/bar/baz')
  end
end


#     project_deploy_keys GET    /:project_id/deploy_keys(.:format)          deploy_keys#index
#                         POST   /:project_id/deploy_keys(.:format)          deploy_keys#create
#  new_project_deploy_key GET    /:project_id/deploy_keys/new(.:format)      deploy_keys#new
#      project_deploy_key GET    /:project_id/deploy_keys/:id(.:format)      deploy_keys#show
#                         DELETE /:project_id/deploy_keys/:id(.:format)      deploy_keys#destroy
describe Projects::DeployKeysController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:index, :new, :create] }
    let(:controller) { 'deploy_keys' }
  end
end

# project_protected_branches GET    /:project_id/protected_branches(.:format)     protected_branches#index
#                            POST   /:project_id/protected_branches(.:format)     protected_branches#create
#   project_protected_branch DELETE /:project_id/protected_branches/:id(.:format) protected_branches#destroy
describe Projects::ProtectedBranchesController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'protected_branches' }
  end
end

#    switch_project_refs GET    /:project_id/refs/switch(.:format)              refs#switch
#  logs_tree_project_ref GET    /:project_id/refs/:id/logs_tree(.:format)       refs#logs_tree
#  logs_file_project_ref GET    /:project_id/refs/:id/logs_tree/:path(.:format) refs#logs_tree
describe Projects::RefsController, 'routing' do
  it 'to #switch' do
    expect(get('/gitlab/gitlabhq/refs/switch')).to route_to('projects/refs#switch', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #logs_tree' do
    expect(get('/gitlab/gitlabhq/refs/stable/logs_tree')).to             route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable')
    expect(get('/gitlab/gitlabhq/refs/feature%2345/logs_tree')).to             route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45')
    expect(get('/gitlab/gitlabhq/refs/feature%2B45/logs_tree')).to             route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45')
    expect(get('/gitlab/gitlabhq/refs/feature@45/logs_tree')).to             route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45')
    expect(get('/gitlab/gitlabhq/refs/stable/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable', path: 'foo/bar/baz')
    expect(get('/gitlab/gitlabhq/refs/feature%2345/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature#45', path: 'foo/bar/baz')
    expect(get('/gitlab/gitlabhq/refs/feature%2B45/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature+45', path: 'foo/bar/baz')
    expect(get('/gitlab/gitlabhq/refs/feature@45/logs_tree/foo/bar/baz')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'feature@45', path: 'foo/bar/baz')
    expect(get('/gitlab/gitlabhq/refs/stable/logs_tree/files.scss')).to route_to('projects/refs#logs_tree', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'stable', path: 'files.scss')
  end
end

#               diffs_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id/diffs(.:format)               projects/merge_requests#diffs
#             commits_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id/commits(.:format)             projects/merge_requests#commits
#           merge_namespace_project_merge_request POST     /:namespace_id/:project_id/merge_requests/:id/merge(.:format)           projects/merge_requests#merge
#     merge_check_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id/merge_check(.:format)     projects/merge_requests#merge_check
#           ci_status_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id/ci_status(.:format)           projects/merge_requests#ci_status
# toggle_subscription_namespace_project_merge_request POST     /:namespace_id/:project_id/merge_requests/:id/toggle_subscription(.:format) projects/merge_requests#toggle_subscription
#        branch_from_namespace_project_merge_requests GET      /:namespace_id/:project_id/merge_requests/branch_from(.:format)             projects/merge_requests#branch_from
#          branch_to_namespace_project_merge_requests GET      /:namespace_id/:project_id/merge_requests/branch_to(.:format)               projects/merge_requests#branch_to
#    update_branches_namespace_project_merge_requests GET      /:namespace_id/:project_id/merge_requests/update_branches(.:format)         projects/merge_requests#update_branches
#                    namespace_project_merge_requests GET      /:namespace_id/:project_id/merge_requests(.:format)                         projects/merge_requests#index
#                                                     POST     /:namespace_id/:project_id/merge_requests(.:format)                         projects/merge_requests#create
#                 new_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/new(.:format)                     projects/merge_requests#new
#                edit_namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id/edit(.:format)                projects/merge_requests#edit
#                     namespace_project_merge_request GET      /:namespace_id/:project_id/merge_requests/:id(.:format)                     projects/merge_requests#show
#                                                     PATCH    /:namespace_id/:project_id/merge_requests/:id(.:format)                     projects/merge_requests#update
#                                                     PUT      /:namespace_id/:project_id/merge_requests/:id(.:format)                     projects/merge_requests#update
describe Projects::MergeRequestsController, 'routing' do
  it 'to #diffs' do
    expect(get('/gitlab/gitlabhq/merge_requests/1/diffs')).to route_to('projects/merge_requests#diffs', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #commits' do
    expect(get('/gitlab/gitlabhq/merge_requests/1/commits')).to route_to('projects/merge_requests#commits', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #merge' do
    expect(post('/gitlab/gitlabhq/merge_requests/1/merge')).to route_to(
      'projects/merge_requests#merge',
      namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1'
    )
  end

  it 'to #merge_check' do
    expect(get('/gitlab/gitlabhq/merge_requests/1/merge_check')).to route_to('projects/merge_requests#merge_check', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #branch_from' do
    expect(get('/gitlab/gitlabhq/merge_requests/branch_from')).to route_to('projects/merge_requests#branch_from', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #branch_to' do
    expect(get('/gitlab/gitlabhq/merge_requests/branch_to')).to route_to('projects/merge_requests#branch_to', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq/merge_requests/1.diff')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'diff')
    expect(get('/gitlab/gitlabhq/merge_requests/1.patch')).to route_to('projects/merge_requests#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', format: 'patch')
  end

  it_behaves_like 'RESTful project resources' do
    let(:controller) { 'merge_requests' }
    let(:actions) { [:index, :create, :new, :edit, :show, :update] }
  end
end

#  raw_project_snippet GET    /:project_id/snippets/:id/raw(.:format)  snippets#raw
#     project_snippets GET    /:project_id/snippets(.:format)          snippets#index
#                      POST   /:project_id/snippets(.:format)          snippets#create
#  new_project_snippet GET    /:project_id/snippets/new(.:format)      snippets#new
# edit_project_snippet GET    /:project_id/snippets/:id/edit(.:format) snippets#edit
#      project_snippet GET    /:project_id/snippets/:id(.:format)      snippets#show
#                      PUT    /:project_id/snippets/:id(.:format)      snippets#update
#                      DELETE /:project_id/snippets/:id(.:format)      snippets#destroy
describe SnippetsController, 'routing' do
  it 'to #raw' do
    expect(get('/gitlab/gitlabhq/snippets/1/raw')).to route_to('projects/snippets#raw', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #index' do
    expect(get('/gitlab/gitlabhq/snippets')).to route_to('projects/snippets#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #create' do
    expect(post('/gitlab/gitlabhq/snippets')).to route_to('projects/snippets#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #new' do
    expect(get('/gitlab/gitlabhq/snippets/new')).to route_to('projects/snippets#new', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #edit' do
    expect(get('/gitlab/gitlabhq/snippets/1/edit')).to route_to('projects/snippets#edit', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #update' do
    expect(put('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#update', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it 'to #destroy' do
    expect(delete('/gitlab/gitlabhq/snippets/1')).to route_to('projects/snippets#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end
end

# test_project_hook GET    /:project_id/hooks/:id/test(.:format) hooks#test
#     project_hooks GET    /:project_id/hooks(.:format)          hooks#index
#                   POST   /:project_id/hooks(.:format)          hooks#create
#      project_hook DELETE /:project_id/hooks/:id(.:format)      hooks#destroy
describe Projects::HooksController, 'routing' do
  it 'to #test' do
    expect(get('/gitlab/gitlabhq/hooks/1/test')).to route_to('projects/hooks#test', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'hooks' }
  end
end

# project_commit GET    /:project_id/commit/:id(.:format) commit#show {id: /\h{7,40}/, project_id: /[^\/]+/}
describe Projects::CommitController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/commit/4246fbd')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd')
    expect(get('/gitlab/gitlabhq/commit/4246fbd.diff')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd', format: 'diff')
    expect(get('/gitlab/gitlabhq/commit/4246fbd.patch')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd', format: 'patch')
    expect(get('/gitlab/gitlabhq/commit/4246fbd13872934f72a8fd0d6fb1317b47b59cb5')).to route_to('projects/commit#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '4246fbd13872934f72a8fd0d6fb1317b47b59cb5')
  end
end

#    patch_project_commit GET    /:project_id/commits/:id/patch(.:format) commits#patch
#         project_commits GET    /:project_id/commits(.:format)           commits#index
#                         POST   /:project_id/commits(.:format)           commits#create
#          project_commit GET    /:project_id/commits/:id(.:format)       commits#show
describe Projects::CommitsController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:show] }
    let(:controller) { 'commits' }
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq/commits/master.atom')).to route_to('projects/commits#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', format: 'atom')
  end
end

#     project_project_members GET    /:project_id/project_members(.:format)          project_members#index
#                          POST   /:project_id/project_members(.:format)          project_members#create
#                          PUT    /:project_id/project_members/:id(.:format)      project_members#update
#                          DELETE /:project_id/project_members/:id(.:format)      project_members#destroy
describe Projects::ProjectMembersController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:index, :create, :update, :destroy] }
    let(:controller) { 'project_members' }
  end
end

#     project_milestones GET    /:project_id/milestones(.:format)          milestones#index
#                        POST   /:project_id/milestones(.:format)          milestones#create
#  new_project_milestone GET    /:project_id/milestones/new(.:format)      milestones#new
# edit_project_milestone GET    /:project_id/milestones/:id/edit(.:format) milestones#edit
#      project_milestone GET    /:project_id/milestones/:id(.:format)      milestones#show
#                        PUT    /:project_id/milestones/:id(.:format)      milestones#update
#                        DELETE /:project_id/milestones/:id(.:format)      milestones#destroy
describe Projects::MilestonesController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:controller) { 'milestones' }
    let(:actions) { [:index, :create, :new, :edit, :show, :update] }
  end
end

# project_labels GET    /:project_id/labels(.:format) labels#index
describe Projects::LabelsController, 'routing' do
  it 'to #index' do
    expect(get('/gitlab/gitlabhq/labels')).to route_to('projects/labels#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end
end

#        sort_project_issues POST   /:project_id/issues/sort(.:format)        issues#sort
# bulk_update_project_issues POST   /:project_id/issues/bulk_update(.:format) issues#bulk_update
#      search_project_issues GET    /:project_id/issues/search(.:format)      issues#search
#             project_issues GET    /:project_id/issues(.:format)             issues#index
#                            POST   /:project_id/issues(.:format)             issues#create
#          new_project_issue GET    /:project_id/issues/new(.:format)         issues#new
#         edit_project_issue GET    /:project_id/issues/:id/edit(.:format)    issues#edit
#              project_issue GET    /:project_id/issues/:id(.:format)         issues#show
#                            PUT    /:project_id/issues/:id(.:format)         issues#update
#                            DELETE /:project_id/issues/:id(.:format)         issues#destroy
describe Projects::IssuesController, 'routing' do
  it 'to #bulk_update' do
    expect(post('/gitlab/gitlabhq/issues/bulk_update')).to route_to('projects/issues#bulk_update', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it_behaves_like 'RESTful project resources' do
    let(:controller) { 'issues' }
    let(:actions) { [:index, :create, :new, :edit, :show, :update] }
  end
end

#         project_notes GET    /:project_id/notes(.:format)         notes#index
#                       POST   /:project_id/notes(.:format)         notes#create
#          project_note DELETE /:project_id/notes/:id(.:format)     notes#destroy
describe Projects::NotesController, 'routing' do
  it_behaves_like 'RESTful project resources' do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'notes' }
  end
end

# project_blame GET    /:project_id/blame/:id(.:format) blame#show {id: /.+/, project_id: /[^\/]+/}
describe Projects::BlameController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/blame/master/app/models/project.rb')).to route_to('projects/blame#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
    expect(get('/gitlab/gitlabhq/blame/master/files.scss')).to route_to('projects/blame#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
  end
end

# project_blob GET    /:project_id/blob/:id(.:format) blob#show {id: /.+/, project_id: /[^\/]+/}
describe Projects::BlobController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/blob/master/app/models/project.rb')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
    expect(get('/gitlab/gitlabhq/blob/master/app/models/compare.rb')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/compare.rb')
    expect(get('/gitlab/gitlabhq/blob/master/app/models/diff.js')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/diff.js')
    expect(get('/gitlab/gitlabhq/blob/master/files.scss')).to route_to('projects/blob#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
  end
end

# project_tree GET    /:project_id/tree/:id(.:format) tree#show {id: /.+/, project_id: /[^\/]+/}
describe Projects::TreeController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/tree/master/app/models/project.rb')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/app/models/project.rb')
    expect(get('/gitlab/gitlabhq/tree/master/files.scss')).to route_to('projects/tree#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master/files.scss')
  end
end

# project_find_file GET /:namespace_id/:project_id/find_file/*id(.:format)  projects/find_file#show {:id=>/.+/, :namespace_id=>/[a-zA-Z.0-9_\-]+/, :project_id=>/[a-zA-Z.0-9_\-]+(?<!\.atom)/, :format=>/html/}
# project_files     GET /:namespace_id/:project_id/files/*id(.:format)      projects/find_file#list {:id=>/(?:[^.]|\.(?!json$))+/, :namespace_id=>/[a-zA-Z.0-9_\-]+/, :project_id=>/[a-zA-Z.0-9_\-]+(?<!\.atom)/, :format=>/json/}
describe Projects::FindFileController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/find_file/master')).to route_to('projects/find_file#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
  end

  it 'to #list' do
    expect(get('/gitlab/gitlabhq/files/master.json')).to route_to('projects/find_file#list', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', format: 'json')
  end
end

describe Projects::BlobController, 'routing' do
  it 'to #edit' do
    expect(get('/gitlab/gitlabhq/edit/master/app/models/project.rb')).to(
      route_to('projects/blob#edit',
               namespace_id: 'gitlab', project_id: 'gitlabhq',
               id: 'master/app/models/project.rb'))
  end

  it 'to #preview' do
    expect(post('/gitlab/gitlabhq/preview/master/app/models/project.rb')).to(
      route_to('projects/blob#preview',
               namespace_id: 'gitlab', project_id: 'gitlabhq',
               id: 'master/app/models/project.rb'))
  end
end

# project_compare_index GET    /:project_id/compare(.:format)             compare#index {id: /[^\/]+/, project_id: /[^\/]+/}
#                       POST   /:project_id/compare(.:format)             compare#create {id: /[^\/]+/, project_id: /[^\/]+/}
#       project_compare        /:project_id/compare/:from...:to(.:format) compare#show {from: /.+/, to: /.+/, id: /[^\/]+/, project_id: /[^\/]+/}
describe Projects::CompareController, 'routing' do
  it 'to #index' do
    expect(get('/gitlab/gitlabhq/compare')).to route_to('projects/compare#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #compare' do
    expect(post('/gitlab/gitlabhq/compare')).to route_to('projects/compare#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #show' do
    expect(get('/gitlab/gitlabhq/compare/master...stable')).to     route_to('projects/compare#show', namespace_id: 'gitlab', project_id: 'gitlabhq', from: 'master', to: 'stable')
    expect(get('/gitlab/gitlabhq/compare/issue/1234...stable')).to route_to('projects/compare#show', namespace_id: 'gitlab', project_id: 'gitlabhq', from: 'issue/1234', to: 'stable')
  end
end

describe Projects::NetworkController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/network/master')).to route_to('projects/network#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
    expect(get('/gitlab/gitlabhq/network/master.json')).to route_to('projects/network#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master', format: 'json')
  end
end

describe Projects::GraphsController, 'routing' do
  it 'to #show' do
    expect(get('/gitlab/gitlabhq/graphs/master')).to route_to('projects/graphs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: 'master')
  end
end

describe Projects::ForksController, 'routing' do
  it 'to #new' do
    expect(get('/gitlab/gitlabhq/forks/new')).to route_to('projects/forks#new', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end

  it 'to #create' do
    expect(post('/gitlab/gitlabhq/forks')).to route_to('projects/forks#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end
end

# project_avatar DELETE /project/avatar(.:format) projects/avatars#destroy
describe Projects::AvatarsController, 'routing' do
  it 'to #destroy' do
    expect(delete('/gitlab/gitlabhq/avatar')).to route_to(
      'projects/avatars#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end
end
