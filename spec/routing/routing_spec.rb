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
#   it_behaves_like "RESTful project resources" do
#     let(:controller) { 'issues' }
#   end
#
#   # Customizing actions
#   it_behaves_like "RESTful project resources" do
#     let(:actions)    { [:index] }
#     let(:controller) { 'issues' }
#   end
shared_examples "RESTful project resources" do
  let(:actions) { [:index, :create, :new, :edit, :show, :update, :destroy] }

  it "to #index" do
    get("/gitlabhq/#{controller}").should route_to("#{controller}#index", project_id: 'gitlabhq') if actions.include?(:index)
  end

  it "to #create" do
    post("/gitlabhq/#{controller}").should route_to("#{controller}#create", project_id: 'gitlabhq') if actions.include?(:create)
  end

  it "to #new" do
    get("/gitlabhq/#{controller}/new").should route_to("#{controller}#new", project_id: 'gitlabhq') if actions.include?(:new)
  end

  it "to #edit" do
    get("/gitlabhq/#{controller}/1/edit").should route_to("#{controller}#edit", project_id: 'gitlabhq', id: '1') if actions.include?(:edit)
  end

  it "to #show" do
    get("/gitlabhq/#{controller}/1").should route_to("#{controller}#show", project_id: 'gitlabhq', id: '1') if actions.include?(:show)
  end

  it "to #update" do
    put("/gitlabhq/#{controller}/1").should route_to("#{controller}#update", project_id: 'gitlabhq', id: '1') if actions.include?(:update)
  end

  it "to #destroy" do
    delete("/gitlabhq/#{controller}/1").should route_to("#{controller}#destroy", project_id: 'gitlabhq', id: '1') if actions.include?(:destroy)
  end
end

# search GET    /search(.:format) search#show
describe SearchController, "routing" do
  it "to #show" do
    get("/search").should route_to('search#show')
  end
end

# gitlab_api /api         Gitlab::API
#     resque /info/resque Resque::Server
#            /:path       Grack
describe "Mounted Apps", "routing" do
  it "to API" do
    get("/api").should be_routable
  end

  it "to Resque" do
    pending
    get("/info/resque").should be_routable
  end

  it "to Grack" do
    get("/gitlabhq.git").should be_routable
  end
end

#              help GET    /help(.:format)              help#index
#  help_permissions GET    /help/permissions(.:format)  help#permissions
#     help_workflow GET    /help/workflow(.:format)     help#workflow
#          help_api GET    /help/api(.:format)          help#api
#    help_web_hooks GET    /help/web_hooks(.:format)    help#web_hooks
# help_system_hooks GET    /help/system_hooks(.:format) help#system_hooks
#     help_markdown GET    /help/markdown(.:format)     help#markdown
#          help_ssh GET    /help/ssh(.:format)          help#ssh
describe HelpController, "routing" do
  it "to #index" do
    get("/help").should route_to('help#index')
  end

  it "to #permissions" do
    get("/help/permissions").should route_to('help#permissions')
  end

  it "to #workflow" do
    get("/help/workflow").should route_to('help#workflow')
  end

  it "to #api" do
    get("/help/api").should route_to('help#api')
  end

  it "to #web_hooks" do
    get("/help/web_hooks").should route_to('help#web_hooks')
  end

  it "to #system_hooks" do
    get("/help/system_hooks").should route_to('help#system_hooks')
  end

  it "to #markdown" do
    get("/help/markdown").should route_to('help#markdown')
  end

  it "to #ssh" do
    get("/help/ssh").should route_to('help#ssh')
  end
end

# errors_githost GET    /errors/githost(.:format) errors#githost
describe ErrorsController, "routing" do
  it "to #githost" do
    get("/errors/githost").should route_to('errors#githost')
  end
end

#             profile_account GET    /profile/account(.:format)             profile#account
#             profile_history GET    /profile/history(.:format)             profile#history
#            profile_password PUT    /profile/password(.:format)            profile#password_update
#               profile_token GET    /profile/token(.:format)               profile#token
# profile_reset_private_token PUT    /profile/reset_private_token(.:format) profile#reset_private_token
#                     profile GET    /profile(.:format)                     profile#show
#              profile_design GET    /profile/design(.:format)              profile#design
#              profile_update PUT    /profile/update(.:format)              profile#update
describe ProfileController, "routing" do
  it "to #account" do
    get("/profile/account").should route_to('profile#account')
  end

  it "to #history" do
    get("/profile/history").should route_to('profile#history')
  end

  it "to #password_update" do
    put("/profile/password").should route_to('profile#password_update')
  end

  it "to #token" do
    get("/profile/token").should route_to('profile#token')
  end

  it "to #reset_private_token" do
    put("/profile/reset_private_token").should route_to('profile#reset_private_token')
  end

  it "to #show" do
    get("/profile").should route_to('profile#show')
  end

  it "to #design" do
    get("/profile/design").should route_to('profile#design')
  end

  it "to #update" do
    put("/profile/update").should route_to('profile#update')
  end
end

#     keys GET    /keys(.:format)          keys#index
#          POST   /keys(.:format)          keys#create
#  new_key GET    /keys/new(.:format)      keys#new
# edit_key GET    /keys/:id/edit(.:format) keys#edit
#      key GET    /keys/:id(.:format)      keys#show
#          PUT    /keys/:id(.:format)      keys#update
#          DELETE /keys/:id(.:format)      keys#destroy
describe KeysController, "routing" do
  it "to #index" do
    get("/keys").should route_to('keys#index')
  end

  it "to #create" do
    post("/keys").should route_to('keys#create')
  end

  it "to #new" do
    get("/keys/new").should route_to('keys#new')
  end

  it "to #edit" do
    get("/keys/1/edit").should route_to('keys#edit', id: '1')
  end

  it "to #show" do
    get("/keys/1").should route_to('keys#show', id: '1')
  end

  it "to #update" do
    put("/keys/1").should route_to('keys#update', id: '1')
  end

  it "to #destroy" do
    delete("/keys/1").should route_to('keys#destroy', id: '1')
  end
end

#                dashboard GET    /dashboard(.:format)                dashboard#index
#         dashboard_issues GET    /dashboard/issues(.:format)         dashboard#issues
# dashboard_merge_requests GET    /dashboard/merge_requests(.:format) dashboard#merge_requests
#                     root        /                                   dashboard#index
describe DashboardController, "routing" do
  it "to #index" do
    get("/dashboard").should route_to('dashboard#index')
    get("/").should route_to('dashboard#index')
  end

  it "to #issues" do
    get("/dashboard/issues").should route_to('dashboard#issues')
  end

  it "to #merge_requests" do
    get("/dashboard/merge_requests").should route_to('dashboard#merge_requests')
  end
end

#      projects POST   /projects(.:format)     projects#create
#   new_project GET    /projects/new(.:format) projects#new
#  team_project GET    /:id/team(.:format)     projects#team
#  wall_project GET    /:id/wall(.:format)     projects#wall
# graph_project GET    /:id/graph(.:format)    projects#graph
# files_project GET    /:id/files(.:format)    projects#files
#  edit_project GET    /:id/edit(.:format)     projects#edit
#       project GET    /:id(.:format)          projects#show
#               PUT    /:id(.:format)          projects#update
#               DELETE /:id(.:format)          projects#destroy
describe ProjectsController, "routing" do
  it "to #create" do
    post("/projects").should route_to('projects#create')
  end

  it "to #new" do
    get("/projects/new").should route_to('projects#new')
  end

  it "to #team" do
    get("/gitlabhq/team").should route_to('projects#team', id: 'gitlabhq')
  end

  it "to #wall" do
    get("/gitlabhq/wall").should route_to('projects#wall', id: 'gitlabhq')
  end

  it "to #graph" do
    get("/gitlabhq/graph").should route_to('projects#graph', id: 'gitlabhq')
  end

  it "to #files" do
    get("/gitlabhq/files").should route_to('projects#files', id: 'gitlabhq')
  end

  it "to #edit" do
    get("/gitlabhq/edit").should route_to('projects#edit', id: 'gitlabhq')
  end

  it "to #show" do
    get("/gitlabhq").should route_to('projects#show', id: 'gitlabhq')
  end

  it "to #update" do
    put("/gitlabhq").should route_to('projects#update', id: 'gitlabhq')
  end

  it "to #destroy" do
    delete("/gitlabhq").should route_to('projects#destroy', id: 'gitlabhq')
  end
end

#        new_user_session GET    /users/sign_in(.:format)               devise/sessions#new
#            user_session POST   /users/sign_in(.:format)               devise/sessions#create
#    destroy_user_session DELETE /users/sign_out(.:format)              devise/sessions#destroy
# user_omniauth_authorize        /users/auth/:provider(.:format)        omniauth_callbacks#passthru
#  user_omniauth_callback        /users/auth/:action/callback(.:format) omniauth_callbacks#(?-mix:(?!))
#           user_password POST   /users/password(.:format)              devise/passwords#create
#       new_user_password GET    /users/password/new(.:format)          devise/passwords#new
#      edit_user_password GET    /users/password/edit(.:format)         devise/passwords#edit
#                         PUT    /users/password(.:format)              devise/passwords#update
describe "Authentication", "routing" do
  # pending
end

#  pages_project_wikis GET    /:project_id/wikis/pages(.:format)       wikis#pages
# history_project_wiki GET    /:project_id/wikis/:id/history(.:format) wikis#history
#        project_wikis POST   /:project_id/wikis(.:format)             wikis#create
#    edit_project_wiki GET    /:project_id/wikis/:id/edit(.:format)    wikis#edit
#         project_wiki GET    /:project_id/wikis/:id(.:format)         wikis#show
#                      DELETE /:project_id/wikis/:id(.:format)         wikis#destroy
describe WikisController, "routing" do
  it "to #pages" do
    get("/gitlabhq/wikis/pages").should route_to('wikis#pages', project_id: 'gitlabhq')
  end

  it "to #history" do
    get("/gitlabhq/wikis/1/history").should route_to('wikis#history', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like "RESTful project resources" do
    let(:actions)    { [:create, :edit, :show, :destroy] }
    let(:controller) { 'wikis' }
  end
end

# branches_project_repository GET    /:project_id/repository/branches(.:format) repositories#branches
#     tags_project_repository GET    /:project_id/repository/tags(.:format)     repositories#tags
#  archive_project_repository GET    /:project_id/repository/archive(.:format)  repositories#archive
#          project_repository POST   /:project_id/repository(.:format)          repositories#create
#      new_project_repository GET    /:project_id/repository/new(.:format)      repositories#new
#     edit_project_repository GET    /:project_id/repository/edit(.:format)     repositories#edit
#                             GET    /:project_id/repository(.:format)          repositories#show
#                             PUT    /:project_id/repository(.:format)          repositories#update
#                             DELETE /:project_id/repository(.:format)          repositories#destroy
describe RepositoriesController, "routing" do
  it "to #branches" do
    get("/gitlabhq/repository/branches").should route_to('repositories#branches', project_id: 'gitlabhq')
  end

  it "to #tags" do
    get("/gitlabhq/repository/tags").should route_to('repositories#tags', project_id: 'gitlabhq')
  end

  it "to #archive" do
    get("/gitlabhq/repository/archive").should route_to('repositories#archive', project_id: 'gitlabhq')
  end

  it "to #create" do
    post("/gitlabhq/repository").should route_to('repositories#create', project_id: 'gitlabhq')
  end

  it "to #new" do
    get("/gitlabhq/repository/new").should route_to('repositories#new', project_id: 'gitlabhq')
  end

  it "to #edit" do
    get("/gitlabhq/repository/edit").should route_to('repositories#edit', project_id: 'gitlabhq')
  end

  it "to #show" do
    get("/gitlabhq/repository").should route_to('repositories#show', project_id: 'gitlabhq')
  end

  it "to #update" do
    put("/gitlabhq/repository").should route_to('repositories#update', project_id: 'gitlabhq')
  end

  it "to #destroy" do
    delete("/gitlabhq/repository").should route_to('repositories#destroy', project_id: 'gitlabhq')
  end
end

#     project_deploy_keys GET    /:project_id/deploy_keys(.:format)          deploy_keys#index
#                         POST   /:project_id/deploy_keys(.:format)          deploy_keys#create
#  new_project_deploy_key GET    /:project_id/deploy_keys/new(.:format)      deploy_keys#new
# edit_project_deploy_key GET    /:project_id/deploy_keys/:id/edit(.:format) deploy_keys#edit
#      project_deploy_key GET    /:project_id/deploy_keys/:id(.:format)      deploy_keys#show
#                         PUT    /:project_id/deploy_keys/:id(.:format)      deploy_keys#update
#                         DELETE /:project_id/deploy_keys/:id(.:format)      deploy_keys#destroy
describe DeployKeysController, "routing" do
  it_behaves_like "RESTful project resources" do
    let(:controller) { 'deploy_keys' }
  end
end

# project_protected_branches GET    /:project_id/protected_branches(.:format)     protected_branches#index
#                            POST   /:project_id/protected_branches(.:format)     protected_branches#create
#   project_protected_branch DELETE /:project_id/protected_branches/:id(.:format) protected_branches#destroy
describe ProtectedBranchesController, "routing" do
  it_behaves_like "RESTful project resources" do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'protected_branches' }
  end
end

#    switch_project_refs GET    /:project_id/switch(.:format)              refs#switch
#       tree_project_ref GET    /:project_id/:id/tree(.:format)            refs#tree
#  logs_tree_project_ref GET    /:project_id/:id/logs_tree(.:format)       refs#logs_tree
#       blob_project_ref GET    /:project_id/:id/blob(.:format)            refs#blob
#  tree_file_project_ref GET    /:project_id/:id/tree/:path(.:format)      refs#tree
#  logs_file_project_ref GET    /:project_id/:id/logs_tree/:path(.:format) refs#logs_tree
# blame_file_project_ref GET    /:project_id/:id/blame/:path(.:format)     refs#blame
describe RefsController, "routing" do
  it "to #switch" do
    get("/gitlabhq/switch").should route_to('refs#switch', project_id: 'gitlabhq')
  end

  it "to #tree" do
    get("/gitlabhq/stable/tree").should             route_to('refs#tree', project_id: 'gitlabhq', id: 'stable')
    get("/gitlabhq/stable/tree/foo/bar/baz").should route_to('refs#tree', project_id: 'gitlabhq', id: 'stable', path: 'foo/bar/baz')
  end

  it "to #logs_tree" do
    get("/gitlabhq/stable/logs_tree").should             route_to('refs#logs_tree', project_id: 'gitlabhq', id: 'stable')
    get("/gitlabhq/stable/logs_tree/foo/bar/baz").should route_to('refs#logs_tree', project_id: 'gitlabhq', id: 'stable', path: 'foo/bar/baz')
  end

  it "to #blob" do
    get("/gitlabhq/stable/blob").should route_to('refs#blob', project_id: 'gitlabhq', id: 'stable')
  end

  it "to #blame" do
    get("/gitlabhq/stable/blame/foo/bar/baz").should route_to('refs#blame', project_id: 'gitlabhq', id: 'stable', path: 'foo/bar/baz')
  end
end

#           diffs_project_merge_request GET    /:project_id/merge_requests/:id/diffs(.:format)           merge_requests#diffs
#       automerge_project_merge_request GET    /:project_id/merge_requests/:id/automerge(.:format)       merge_requests#automerge
# automerge_check_project_merge_request GET    /:project_id/merge_requests/:id/automerge_check(.:format) merge_requests#automerge_check
#             raw_project_merge_request GET    /:project_id/merge_requests/:id/raw(.:format)             merge_requests#raw
#    branch_from_project_merge_requests GET    /:project_id/merge_requests/branch_from(.:format)         merge_requests#branch_from
#      branch_to_project_merge_requests GET    /:project_id/merge_requests/branch_to(.:format)           merge_requests#branch_to
#                project_merge_requests GET    /:project_id/merge_requests(.:format)                     merge_requests#index
#                                       POST   /:project_id/merge_requests(.:format)                     merge_requests#create
#             new_project_merge_request GET    /:project_id/merge_requests/new(.:format)                 merge_requests#new
#            edit_project_merge_request GET    /:project_id/merge_requests/:id/edit(.:format)            merge_requests#edit
#                 project_merge_request GET    /:project_id/merge_requests/:id(.:format)                 merge_requests#show
#                                       PUT    /:project_id/merge_requests/:id(.:format)                 merge_requests#update
#                                       DELETE /:project_id/merge_requests/:id(.:format)                 merge_requests#destroy
describe MergeRequestsController, "routing" do
  it "to #diffs" do
    get("/gitlabhq/merge_requests/1/diffs").should route_to('merge_requests#diffs', project_id: 'gitlabhq', id: '1')
  end

  it "to #automerge" do
    get("/gitlabhq/merge_requests/1/automerge").should route_to('merge_requests#automerge', project_id: 'gitlabhq', id: '1')
  end

  it "to #automerge_check" do
    get("/gitlabhq/merge_requests/1/automerge_check").should route_to('merge_requests#automerge_check', project_id: 'gitlabhq', id: '1')
  end

  it "to #raw" do
    get("/gitlabhq/merge_requests/1/raw").should route_to('merge_requests#raw', project_id: 'gitlabhq', id: '1')
  end

  it "to #branch_from" do
    get("/gitlabhq/merge_requests/branch_from").should route_to('merge_requests#branch_from', project_id: 'gitlabhq')
  end

  it "to #branch_to" do
    get("/gitlabhq/merge_requests/branch_to").should route_to('merge_requests#branch_to', project_id: 'gitlabhq')
  end

  it_behaves_like "RESTful project resources" do
    let(:controller) { 'merge_requests' }
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
describe SnippetsController, "routing" do
  it "to #raw" do
    get("/gitlabhq/snippets/1/raw").should route_to('snippets#raw', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like "RESTful project resources" do
    let(:controller) { 'snippets' }
  end
end

# test_project_hook GET    /:project_id/hooks/:id/test(.:format) hooks#test
#     project_hooks GET    /:project_id/hooks(.:format)          hooks#index
#                   POST   /:project_id/hooks(.:format)          hooks#create
#      project_hook DELETE /:project_id/hooks/:id(.:format)      hooks#destroy
describe HooksController, "routing" do
  it "to #test" do
    get("/gitlabhq/hooks/1/test").should route_to('hooks#test', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like "RESTful project resources" do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'hooks' }
  end
end

# compare_project_commits GET    /:project_id/commits/compare(.:format)   commits#compare
#    patch_project_commit GET    /:project_id/commits/:id/patch(.:format) commits#patch
#         project_commits GET    /:project_id/commits(.:format)           commits#index
#                         POST   /:project_id/commits(.:format)           commits#create
#      new_project_commit GET    /:project_id/commits/new(.:format)       commits#new
#     edit_project_commit GET    /:project_id/commits/:id/edit(.:format)  commits#edit
#          project_commit GET    /:project_id/commits/:id(.:format)       commits#show
#                         PUT    /:project_id/commits/:id(.:format)       commits#update
#                         DELETE /:project_id/commits/:id(.:format)       commits#destroy
describe CommitsController, "routing" do
  it "to #compare" do
    get("/gitlabhq/commits/compare").should route_to('commits#compare', project_id: 'gitlabhq')
  end

  it "to #patch" do
    get("/gitlabhq/commits/1/patch").should route_to('commits#patch', project_id: 'gitlabhq', id: '1')
  end

  it_behaves_like "RESTful project resources" do
    let(:controller) { 'commits' }
  end
end

#     project_team_members GET    /:project_id/team_members(.:format)          team_members#index
#                          POST   /:project_id/team_members(.:format)          team_members#create
#  new_project_team_member GET    /:project_id/team_members/new(.:format)      team_members#new
# edit_project_team_member GET    /:project_id/team_members/:id/edit(.:format) team_members#edit
#      project_team_member GET    /:project_id/team_members/:id(.:format)      team_members#show
#                          PUT    /:project_id/team_members/:id(.:format)      team_members#update
#                          DELETE /:project_id/team_members/:id(.:format)      team_members#destroy
describe TeamMembersController, "routing" do
  it_behaves_like "RESTful project resources" do
    let(:controller) { 'team_members' }
  end
end

#     project_milestones GET    /:project_id/milestones(.:format)          milestones#index
#                        POST   /:project_id/milestones(.:format)          milestones#create
#  new_project_milestone GET    /:project_id/milestones/new(.:format)      milestones#new
# edit_project_milestone GET    /:project_id/milestones/:id/edit(.:format) milestones#edit
#      project_milestone GET    /:project_id/milestones/:id(.:format)      milestones#show
#                        PUT    /:project_id/milestones/:id(.:format)      milestones#update
#                        DELETE /:project_id/milestones/:id(.:format)      milestones#destroy
describe MilestonesController, "routing" do
  it_behaves_like "RESTful project resources" do
    let(:controller) { 'milestones' }
  end
end

# project_labels GET    /:project_id/labels(.:format) labels#index
describe LabelsController, "routing" do
  it "to #index" do
    get("/gitlabhq/labels").should route_to('labels#index', project_id: 'gitlabhq')
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
describe IssuesController, "routing" do
  it "to #sort" do
    post("/gitlabhq/issues/sort").should route_to('issues#sort', project_id: 'gitlabhq')
  end

  it "to #bulk_update" do
    post("/gitlabhq/issues/bulk_update").should route_to('issues#bulk_update', project_id: 'gitlabhq')
  end

  it "to #search" do
    get("/gitlabhq/issues/search").should route_to('issues#search', project_id: 'gitlabhq')
  end

  it_behaves_like "RESTful project resources" do
    let(:controller) { 'issues' }
  end
end

# preview_project_notes POST   /:project_id/notes/preview(.:format) notes#preview
#         project_notes GET    /:project_id/notes(.:format)         notes#index
#                       POST   /:project_id/notes(.:format)         notes#create
#          project_note DELETE /:project_id/notes/:id(.:format)     notes#destroy
describe NotesController, "routing" do
  it "to #preview" do
    post("/gitlabhq/notes/preview").should route_to('notes#preview', project_id: 'gitlabhq')
  end

  it_behaves_like "RESTful project resources" do
    let(:actions)    { [:index, :create, :destroy] }
    let(:controller) { 'notes' }
  end
end
