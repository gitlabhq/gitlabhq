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
    expect(put("/admin/users/1/team_update")).to route_to('admin/users#team_update', id: '1')
  end

  it "to #block" do
    expect(put("/admin/users/1/block")).to route_to('admin/users#block', id: '1')
  end

  it "to #unblock" do
    expect(put("/admin/users/1/unblock")).to route_to('admin/users#unblock', id: '1')
  end

  it "to #index" do
    expect(get("/admin/users")).to route_to('admin/users#index')
  end

  it "to #show" do
    expect(get("/admin/users/1")).to route_to('admin/users#show', id: '1')
  end

  it "to #create" do
    expect(post("/admin/users")).to route_to('admin/users#create')
  end

  it "to #new" do
    expect(get("/admin/users/new")).to route_to('admin/users#new')
  end

  it "to #edit" do
    expect(get("/admin/users/1/edit")).to route_to('admin/users#edit', id: '1')
  end

  it "to #show" do
    expect(get("/admin/users/1")).to route_to('admin/users#show', id: '1')
  end

  it "to #update" do
    expect(put("/admin/users/1")).to route_to('admin/users#update', id: '1')
  end

  it "to #destroy" do
    expect(delete("/admin/users/1")).to route_to('admin/users#destroy', id: '1')
  end
end

#        team_admin_project GET    /admin/projects/:id/team(.:format)        admin/projects#team {id: /[^\/]+/}
# team_update_admin_project PUT    /admin/projects/:id/team_update(.:format) admin/projects#team_update {id: /[^\/]+/}
#            admin_projects GET    /admin/projects(.:format)                 admin/projects#index {id: /[^\/]+/}
#                           POST   /admin/projects(.:format)                 admin/projects#create {id: /[^\/]+/}
#         new_admin_project GET    /admin/projects/new(.:format)             admin/projects#new {id: /[^\/]+/}
#        edit_admin_project GET    /admin/projects/:id/edit(.:format)        admin/projects#edit {id: /[^\/]+/}
#             admin_project GET    /admin/projects/:id(.:format)             admin/projects#show {id: /[^\/]+/}
#                           PUT    /admin/projects/:id(.:format)             admin/projects#update {id: /[^\/]+/}
#                           DELETE /admin/projects/:id(.:format)             admin/projects#destroy {id: /[^\/]+/}
describe Admin::ProjectsController, "routing" do
  it "to #index" do
    expect(get("/admin/projects")).to route_to('admin/projects#index')
  end

  it "to #show" do
    expect(get("/admin/projects/gitlab")).to route_to('admin/projects#show', namespace_id: 'gitlab')
  end
end

# admin_hook_test GET    /admin/hooks/:hook_id/test(.:format) admin/hooks#test
#     admin_hooks GET    /admin/hooks(.:format)               admin/hooks#index
#                 POST   /admin/hooks(.:format)               admin/hooks#create
#      admin_hook DELETE /admin/hooks/:id(.:format)           admin/hooks#destroy
describe Admin::HooksController, "routing" do
  it "to #test" do
    expect(get("/admin/hooks/1/test")).to route_to('admin/hooks#test', hook_id: '1')
  end

  it "to #index" do
    expect(get("/admin/hooks")).to route_to('admin/hooks#index')
  end

  it "to #create" do
    expect(post("/admin/hooks")).to route_to('admin/hooks#create')
  end

  it "to #destroy" do
    expect(delete("/admin/hooks/1")).to route_to('admin/hooks#destroy', id: '1')
  end

end

# admin_logs GET    /admin/logs(.:format) admin/logs#show
describe Admin::LogsController, "routing" do
  it "to #show" do
    expect(get("/admin/logs")).to route_to('admin/logs#show')
  end
end

# admin_background_jobs GET    /admin/background_jobs(.:format) admin/background_jobs#show
describe Admin::BackgroundJobsController, "routing" do
  it "to #show" do
    expect(get("/admin/background_jobs")).to route_to('admin/background_jobs#show')
  end
end

# admin_root        /admin(.:format) admin/dashboard#index
describe Admin::DashboardController, "routing" do
  it "to #index" do
    expect(get("/admin")).to route_to('admin/dashboard#index')
  end
end
