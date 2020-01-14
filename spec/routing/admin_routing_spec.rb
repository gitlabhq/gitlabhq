# frozen_string_literal: true

require 'spec_helper'

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
    expect(get("/admin/projects/gitlab/gitlab-ce")).to route_to('admin/projects#show', namespace_id: 'gitlab', id: 'gitlab-ce')
    expect(get("/admin/projects/gitlab/subgroup/gitlab-ce")).to route_to('admin/projects#show', namespace_id: 'gitlab/subgroup', id: 'gitlab-ce')
  end
end

# admin_hook_test GET    /admin/hooks/:id/test(.:format)      admin/hooks#test
#     admin_hooks GET    /admin/hooks(.:format)               admin/hooks#index
#                 POST   /admin/hooks(.:format)               admin/hooks#create
#      admin_hook DELETE /admin/hooks/:id(.:format)           admin/hooks#destroy
#                 PUT    /admin/hooks/:id(.:format)           admin/hooks#update
# edit_admin_hook GET    /admin/hooks/:id(.:format)           admin/hooks#edit
describe Admin::HooksController, "routing" do
  it "to #test" do
    expect(post("/admin/hooks/1/test")).to route_to('admin/hooks#test', id: '1')
  end

  it "to #index" do
    expect(get("/admin/hooks")).to route_to('admin/hooks#index')
  end

  it "to #create" do
    expect(post("/admin/hooks")).to route_to('admin/hooks#create')
  end

  it "to #edit" do
    expect(get("/admin/hooks/1/edit")).to route_to('admin/hooks#edit', id: '1')
  end

  it "to #update" do
    expect(put("/admin/hooks/1")).to route_to('admin/hooks#update', id: '1')
  end

  it "to #destroy" do
    expect(delete("/admin/hooks/1")).to route_to('admin/hooks#destroy', id: '1')
  end
end

# admin_hook_hook_log_retry POST    /admin/hooks/:hook_id/hook_logs/:id/retry(.:format) admin/hook_logs#retry
# admin_hook_hook_log       GET    /admin/hooks/:hook_id/hook_logs/:id(.:format)       admin/hook_logs#show
describe Admin::HookLogsController, 'routing' do
  it 'to #retry' do
    expect(post('/admin/hooks/1/hook_logs/1/retry')).to route_to('admin/hook_logs#retry', hook_id: '1', id: '1')
  end

  it 'to #show' do
    expect(get('/admin/hooks/1/hook_logs/1')).to route_to('admin/hook_logs#show', hook_id: '1', id: '1')
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

# admin_health_check GET    /admin/health_check(.:format) admin/health_check#show
describe Admin::HealthCheckController, "routing" do
  it "to #show" do
    expect(get("/admin/health_check")).to route_to('admin/health_check#show')
  end
end

describe Admin::GroupsController, "routing" do
  let(:name) { 'complex.group-namegit' }

  it "to #index" do
    expect(get("/admin/groups")).to route_to('admin/groups#index')
  end

  it "to #show" do
    expect(get("/admin/groups/#{name}")).to route_to('admin/groups#show', id: name)
    expect(get("/admin/groups/#{name}/subgroup")).to route_to('admin/groups#show', id: "#{name}/subgroup")
  end

  it "to #edit" do
    expect(get("/admin/groups/#{name}/edit")).to route_to('admin/groups#edit', id: name)
  end
end

describe Admin::SessionsController, "routing" do
  it "to #new" do
    expect(get("/admin/session/new")).to route_to('admin/sessions#new')
  end

  it "to #create" do
    expect(post("/admin/session")).to route_to('admin/sessions#create')
  end

  it "to #destroy" do
    expect(post("/admin/session/destroy")).to route_to('admin/sessions#destroy')
  end
end
