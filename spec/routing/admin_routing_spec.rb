require 'spec_helper'

# team_update_admin_user PUT    /admin/users/:id/team_update(.:format) admin/users#team_update
#       block_admin_user PUT    /admin/users/:id/block(.:format)       admin/users#block
#     unblock_admin_user PUT    /admin/users/:id/unblock(.:format)     admin/users#unblock
#            admin_users GET    /admin/users(.:format)                 admin/users#index
#                        POST   /admin/users(.:format)                 admin/users#create
#         new_admin_user GET    /admin/users/new(.:format)             admin/users#new
#        edit_admin_user GET    /admin/users/:id/edit(.:format)        admin/users#edit
#             admin_user GET    /admin/users/:id(.:format)             admin/users#show
#                        PUT    /admin/users/:id(.:format)             admin/users#update
#                        DELETE /admin/users/:id(.:format)             admin/users#destroy
describe Admin::UsersController, "routing" do
  it "to #team_update" do
    put("/admin/users/1/team_update").should route_to('admin/users#team_update', id: '1')
  end

  it "to #block" do
    put("/admin/users/1/block").should route_to('admin/users#block', id: '1')
  end

  it "to #unblock" do
    put("/admin/users/1/unblock").should route_to('admin/users#unblock', id: '1')
  end

  it "to #index" do
    get("/admin/users").should route_to('admin/users#index')
  end

  it "to #show" do
    get("/admin/users/1").should route_to('admin/users#show', id: '1')
  end

  it "to #create" do
    post("/admin/users").should route_to('admin/users#create')
  end

  it "to #new" do
    get("/admin/users/new").should route_to('admin/users#new')
  end

  it "to #edit" do
    get("/admin/users/1/edit").should route_to('admin/users#edit', id: '1')
  end

  it "to #show" do
    get("/admin/users/1").should route_to('admin/users#show', id: '1')
  end

  it "to #update" do
    put("/admin/users/1").should route_to('admin/users#update', id: '1')
  end

  it "to #destroy" do
    delete("/admin/users/1").should route_to('admin/users#destroy', id: '1')
  end
end

#        team_admin_project GET    /admin/projects/:id/team(.:format)        admin/projects#team {:id=>/[^\/]+/}
# team_update_admin_project PUT    /admin/projects/:id/team_update(.:format) admin/projects#team_update {:id=>/[^\/]+/}
#            admin_projects GET    /admin/projects(.:format)                 admin/projects#index {:id=>/[^\/]+/}
#                           POST   /admin/projects(.:format)                 admin/projects#create {:id=>/[^\/]+/}
#         new_admin_project GET    /admin/projects/new(.:format)             admin/projects#new {:id=>/[^\/]+/}
#        edit_admin_project GET    /admin/projects/:id/edit(.:format)        admin/projects#edit {:id=>/[^\/]+/}
#             admin_project GET    /admin/projects/:id(.:format)             admin/projects#show {:id=>/[^\/]+/}
#                           PUT    /admin/projects/:id(.:format)             admin/projects#update {:id=>/[^\/]+/}
#                           DELETE /admin/projects/:id(.:format)             admin/projects#destroy {:id=>/[^\/]+/}
describe Admin::ProjectsController, "routing" do
  it "to #team" do
    get("/admin/projects/gitlab/team").should route_to('admin/projects#team', id: 'gitlab')
  end

  it "to #team_update" do
    put("/admin/projects/gitlab/team_update").should route_to('admin/projects#team_update', id: 'gitlab')
  end

  it "to #index" do
    get("/admin/projects").should route_to('admin/projects#index')
  end

  it "to #edit" do
    get("/admin/projects/gitlab/edit").should route_to('admin/projects#edit', id: 'gitlab')
  end

  it "to #show" do
    get("/admin/projects/gitlab").should route_to('admin/projects#show', id: 'gitlab')
  end

  it "to #update" do
    put("/admin/projects/gitlab").should route_to('admin/projects#update', id: 'gitlab')
  end

  it "to #destroy" do
    delete("/admin/projects/gitlab").should route_to('admin/projects#destroy', id: 'gitlab')
  end
end

# edit_admin_project_member GET      /admin/projects/:project_id/members/:id/edit(.:format)    admin/projects/members#edit {:id=>/[^\/]+/, :project_id=>/[^\/]+/}
#      admin_project_member PUT      /admin/projects/:project_id/members/:id(.:format)         admin/projects/members#update {:id=>/[^\/]+/, :project_id=>/[^\/]+/}
#                           DELETE   /admin/projects/:project_id/members/:id(.:format)         admin/projects/members#destroy {:id=>/[^\/]+/, :project_id=>/[^\/]+/}
describe Admin::Projects::MembersController, "routing" do
  it "to #edit" do
    get("/admin/projects/test/members/1/edit").should route_to('admin/projects/members#edit', project_id: 'test', id: '1')
  end

  it "to #update" do
    put("/admin/projects/test/members/1").should route_to('admin/projects/members#update', project_id: 'test', id: '1')
  end

  it "to #destroy" do
    delete("/admin/projects/test/members/1").should route_to('admin/projects/members#destroy', project_id: 'test', id: '1')
  end
end

# admin_hook_test GET    /admin/hooks/:hook_id/test(.:format) admin/hooks#test
#     admin_hooks GET    /admin/hooks(.:format)               admin/hooks#index
#                 POST   /admin/hooks(.:format)               admin/hooks#create
#      admin_hook DELETE /admin/hooks/:id(.:format)           admin/hooks#destroy
describe Admin::HooksController, "routing" do
  it "to #test" do
    get("/admin/hooks/1/test").should route_to('admin/hooks#test', hook_id: '1')
  end

  it "to #index" do
    get("/admin/hooks").should route_to('admin/hooks#index')
  end

  it "to #create" do
    post("/admin/hooks").should route_to('admin/hooks#create')
  end

  it "to #destroy" do
    delete("/admin/hooks/1").should route_to('admin/hooks#destroy', id: '1')
  end

end

# admin_logs GET    /admin/logs(.:format) admin/logs#show
describe Admin::LogsController, "routing" do
  it "to #show" do
    get("/admin/logs").should route_to('admin/logs#show')
  end
end

# admin_resque GET    /admin/resque(.:format) admin/resque#show
describe Admin::ResqueController, "routing" do
  it "to #show" do
    get("/admin/resque").should route_to('admin/resque#show')
  end
end

# admin_root        /admin(.:format) admin/dashboard#index
describe Admin::DashboardController, "routing" do
  it "to #index" do
    get("/admin").should route_to('admin/dashboard#index')
  end
end

