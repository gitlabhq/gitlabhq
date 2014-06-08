require 'spec_helper'

# search GET    /search(.:format) search#show
describe SearchController, "routing" do
  it "to #show" do
    get("/search").should route_to('search#show')
  end
end

# gitlab_api /api         API::API
#            /:path       Grack
describe "Mounted Apps", "routing" do
  it "to API" do
    get("/api/issues").should be_routable
  end

  it "to Grack" do
    get("/gitlab/gitlabhq.git").should be_routable
  end
end

#     snippets GET    /snippets(.:format)          snippets#index
#          POST   /snippets(.:format)          snippets#create
#  new_snippet GET    /snippets/new(.:format)      snippets#new
# edit_snippet GET    /snippets/:id/edit(.:format) snippets#edit
#      snippet GET    /snippets/:id(.:format)      snippets#show
#          PUT    /snippets/:id(.:format)      snippets#update
#          DELETE /snippets/:id(.:format)      snippets#destroy
describe SnippetsController, "routing" do
  it "to #user_index" do
    get("/s/User").should route_to('snippets#user_index', username: 'User')
  end

  it "to #raw" do
    get("/snippets/1/raw").should route_to('snippets#raw', id: '1')
  end

  it "to #index" do
    get("/snippets").should route_to('snippets#index')
  end

  it "to #create" do
    post("/snippets").should route_to('snippets#create')
  end

  it "to #new" do
    get("/snippets/new").should route_to('snippets#new')
  end

  it "to #edit" do
    get("/snippets/1/edit").should route_to('snippets#edit', id: '1')
  end

  it "to #show" do
    get("/snippets/1").should route_to('snippets#show', id: '1')
  end

  it "to #update" do
    put("/snippets/1").should route_to('snippets#update', id: '1')
  end

  it "to #destroy" do
    delete("/snippets/1").should route_to('snippets#destroy', id: '1')
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
#    help_raketasks GET    /help/raketasks(.:format)    help#raketasks
describe HelpController, "routing" do
  it "to #index" do
    get("/help").should route_to('help#index')
  end

  it "to #permissions" do
    get("/help/permissions/permissions").should route_to('help#show', category: "permissions", file: "permissions")
  end

  it "to #workflow" do
    get("/help/workflow/README").should route_to('help#show', category: "workflow", file: "README")
  end

  it "to #api" do
    get("/help/api/README").should route_to('help#show', category: "api", file: "README")
  end

  it "to #web_hooks" do
    get("/help/web_hooks/web_hooks").should route_to('help#show', category: "web_hooks", file: "web_hooks")
  end

  it "to #system_hooks" do
    get("/help/system_hooks/system_hooks").should route_to('help#show', category: "system_hooks", file: "system_hooks")
  end

  it "to #markdown" do
    get("/help/markdown/markdown").should route_to('help#show',category: "markdown", file: "markdown")
  end

  it "to #ssh" do
    get("/help/ssh/README").should route_to('help#show', category: "ssh", file: "README")
  end

  it "to #raketasks" do
    get("/help/raketasks/README").should route_to('help#show', category: "raketasks", file: "README")
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
describe ProfilesController, "routing" do
  it "to #account" do
    get("/profile/account").should route_to('profiles/accounts#show')
  end

  it "to #history" do
    get("/profile/history").should route_to('profiles#history')
  end

  it "to #reset_private_token" do
    put("/profile/reset_private_token").should route_to('profiles#reset_private_token')
  end

  it "to #show" do
    get("/profile").should route_to('profiles#show')
  end

  it "to #design" do
    get("/profile/design").should route_to('profiles#design')
  end
end

#     keys GET    /keys(.:format)          keys#index
#          POST   /keys(.:format)          keys#create
#  new_key GET    /keys/new(.:format)      keys#new
# edit_key GET    /keys/:id/edit(.:format) keys#edit
#      key GET    /keys/:id(.:format)      keys#show
#          PUT    /keys/:id(.:format)      keys#update
#          DELETE /keys/:id(.:format)      keys#destroy
describe Profiles::KeysController, "routing" do
  it "to #index" do
    get("/profile/keys").should route_to('profiles/keys#index')
  end

  it "to #create" do
    post("/profile/keys").should route_to('profiles/keys#create')
  end

  it "to #new" do
    get("/profile/keys/new").should route_to('profiles/keys#new')
  end

  it "to #edit" do
    get("/profile/keys/1/edit").should route_to('profiles/keys#edit', id: '1')
  end

  it "to #show" do
    get("/profile/keys/1").should route_to('profiles/keys#show', id: '1')
  end

  it "to #update" do
    put("/profile/keys/1").should route_to('profiles/keys#update', id: '1')
  end

  it "to #destroy" do
    delete("/profile/keys/1").should route_to('profiles/keys#destroy', id: '1')
  end

  # get all the ssh-keys of a user
  it "to #get_keys" do
    get("/foo.keys").should route_to('profiles/keys#get_keys', username: 'foo')
  end
end

#   emails GET    /emails(.:format)        emails#index
#          POST   /keys(.:format)          emails#create
#          DELETE /keys/:id(.:format)      keys#destroy
describe Profiles::EmailsController, "routing" do
  it "to #index" do
    get("/profile/emails").should route_to('profiles/emails#index')
  end

  it "to #create" do
    post("/profile/emails").should route_to('profiles/emails#create')
  end

  it "to #destroy" do
    delete("/profile/emails/1").should route_to('profiles/emails#destroy', id: '1')
  end
end

# profile_avatar DELETE /profile/avatar(.:format) profiles/avatars#destroy
describe Profiles::AvatarsController, "routing" do
  it "to #destroy" do
    delete("/profile/avatar").should route_to('profiles/avatars#destroy')
  end
end

#                dashboard GET    /dashboard(.:format)                dashboard#show
#         dashboard_issues GET    /dashboard/issues(.:format)         dashboard#issues
# dashboard_merge_requests GET    /dashboard/merge_requests(.:format) dashboard#merge_requests
#                     root        /                                   dashboard#show
describe DashboardController, "routing" do
  it "to #index" do
    get("/dashboard").should route_to('dashboard#show')
    get("/").should route_to('dashboard#show')
  end

  it "to #issues" do
    get("/dashboard/issues").should route_to('dashboard#issues')
  end

  it "to #merge_requests" do
    get("/dashboard/merge_requests").should route_to('dashboard#merge_requests')
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

describe "Groups", "routing" do
  it "to #show" do
    get("/groups/1").should route_to('groups#show', id: '1')
  end

  it "also display group#show on the short path" do
    get('/1').should route_to('namespaces#show', id: '1')
  end
end

