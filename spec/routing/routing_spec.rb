# frozen_string_literal: true

require 'spec_helper'

# user                       GET    /users/:username/
# user_groups                GET    /users/:username/groups(.:format)
# user_projects              GET    /users/:username/projects(.:format)
# user_contributed_projects  GET    /users/:username/contributed(.:format)
# user_snippets              GET    /users/:username/snippets(.:format)
# user_calendar              GET    /users/:username/calendar(.:format)
# user_calendar_activities   GET    /users/:username/calendar_activities(.:format)
describe UsersController, "routing" do
  it "to #show" do
    allow_any_instance_of(::Constraints::UserUrlConstrainer).to receive(:matches?).and_return(true)

    expect(get("/User")).to route_to('users#show', username: 'User')
  end

  it "to #groups" do
    expect(get("/users/User/groups")).to route_to('users#groups', username: 'User')
  end

  it "to #projects" do
    expect(get("/users/User/projects")).to route_to('users#projects', username: 'User')
  end

  it "to #contributed" do
    expect(get("/users/User/contributed")).to route_to('users#contributed', username: 'User')
  end

  it "to #snippets" do
    expect(get("/users/User/snippets")).to route_to('users#snippets', username: 'User')
  end

  it "to #calendar" do
    expect(get("/users/User/calendar")).to route_to('users#calendar', username: 'User')
  end

  it "to #calendar_activities" do
    expect(get("/users/User/calendar_activities")).to route_to('users#calendar_activities', username: 'User')
  end
end

# search GET    /search(.:format) search#show
describe SearchController, "routing" do
  it "to #show" do
    expect(get("/search")).to route_to('search#show')
  end
end

# gitlab_api /api         API::API
#            /:path       Grack
describe "Mounted Apps", "routing" do
  it "to API" do
    expect(get("/api/issues")).to be_routable
  end

  it "to Grack" do
    expect(get("/gitlab/gitlabhq.git")).to be_routable
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
  it "to #raw" do
    expect(get("/snippets/1/raw")).to route_to('snippets#raw', id: '1')
  end

  it "to #index" do
    expect(get("/snippets")).to route_to('snippets#index')
  end

  it "to #create" do
    expect(post("/snippets")).to route_to('snippets#create')
  end

  it "to #new" do
    expect(get("/snippets/new")).to route_to('snippets#new')
  end

  it "to #edit" do
    expect(get("/snippets/1/edit")).to route_to('snippets#edit', id: '1')
  end

  it "to #show" do
    expect(get("/snippets/1")).to route_to('snippets#show', id: '1')
  end

  it "to #update" do
    expect(put("/snippets/1")).to route_to('snippets#update', id: '1')
  end

  it "to #destroy" do
    expect(delete("/snippets/1")).to route_to('snippets#destroy', id: '1')
  end
end

#            help GET /help(.:format)                 help#index
#       help_page GET /help/*path(.:format)           help#show
#  help_shortcuts GET /help/shortcuts(.:format)       help#shortcuts
#         help_ui GET /help/ui(.:format)              help#ui
describe HelpController, "routing" do
  it "to #index" do
    expect(get("/help")).to route_to('help#index')
  end

  it 'to #show' do
    path = '/help/user/markdown.md'
    expect(get(path)).to route_to('help#show',
                                  path: 'user/markdown',
                                  format: 'md')

    path = '/help/workflow/protected_branches/protected_branches1.png'
    expect(get(path)).to route_to('help#show',
                                  path: 'workflow/protected_branches/protected_branches1',
                                  format: 'png')

    path = '/help/ui'
    expect(get(path)).to route_to('help#ui')
  end
end

#             profile_account GET    /profile/account(.:format)             profile#account
#             profile_history GET    /profile/history(.:format)             profile#history
#            profile_password PUT    /profile/password(.:format)            profile#password_update
#               profile_token GET    /profile/token(.:format)               profile#token
#                     profile GET    /profile(.:format)                     profile#show
#              profile_update PUT    /profile/update(.:format)              profile#update
describe ProfilesController, "routing" do
  it "to #account" do
    expect(get("/profile/account")).to route_to('profiles/accounts#show')
  end

  it "to #audit_log" do
    expect(get("/profile/audit_log")).to route_to('profiles#audit_log')
  end

  it "to #reset_feed_token" do
    expect(put("/profile/reset_feed_token")).to route_to('profiles#reset_feed_token')
  end

  it "to #show" do
    expect(get("/profile")).to route_to('profiles#show')
  end
end

# profile_preferences GET      /profile/preferences(.:format) profiles/preferences#show
#                     PATCH    /profile/preferences(.:format) profiles/preferences#update
#                     PUT      /profile/preferences(.:format) profiles/preferences#update
describe Profiles::PreferencesController, 'routing' do
  it 'to #show' do
    expect(get('/profile/preferences')).to route_to('profiles/preferences#show')
  end

  it 'to #update' do
    expect(put('/profile/preferences')).to   route_to('profiles/preferences#update')
    expect(patch('/profile/preferences')).to route_to('profiles/preferences#update')
  end
end

#     keys GET    /keys(.:format)          keys#index
#          POST   /keys(.:format)          keys#create
# edit_key GET    /keys/:id/edit(.:format) keys#edit
#      key GET    /keys/:id(.:format)      keys#show
#          PUT    /keys/:id(.:format)      keys#update
#          DELETE /keys/:id(.:format)      keys#destroy
describe Profiles::KeysController, "routing" do
  it "to #index" do
    expect(get("/profile/keys")).to route_to('profiles/keys#index')
  end

  it "to #create" do
    expect(post("/profile/keys")).to route_to('profiles/keys#create')
  end

  it "to #show" do
    expect(get("/profile/keys/1")).to route_to('profiles/keys#show', id: '1')
  end

  it "to #destroy" do
    expect(delete("/profile/keys/1")).to route_to('profiles/keys#destroy', id: '1')
  end

  # get all the ssh-keys of a user
  it "to #get_keys" do
    allow_any_instance_of(::Constraints::UserUrlConstrainer).to receive(:matches?).and_return(true)

    expect(get("/foo.keys")).to route_to('profiles/keys#get_keys', username: 'foo')
  end
end

#   emails GET    /emails(.:format)        emails#index
#          POST   /keys(.:format)          emails#create
#          DELETE /keys/:id(.:format)      keys#destroy
describe Profiles::EmailsController, "routing" do
  it "to #index" do
    expect(get("/profile/emails")).to route_to('profiles/emails#index')
  end

  it "to #create" do
    expect(post("/profile/emails")).to route_to('profiles/emails#create')
  end

  it "to #destroy" do
    expect(delete("/profile/emails/1")).to route_to('profiles/emails#destroy', id: '1')
  end
end

# profile_avatar DELETE /profile/avatar(.:format) profiles/avatars#destroy
describe Profiles::AvatarsController, "routing" do
  it "to #destroy" do
    expect(delete("/profile/avatar")).to route_to('profiles/avatars#destroy')
  end
end

#                dashboard GET    /dashboard(.:format)                dashboard#show
#         dashboard_issues GET    /dashboard/issues(.:format)         dashboard#issues
# dashboard_merge_requests GET    /dashboard/merge_requests(.:format) dashboard#merge_requests
describe DashboardController, "routing" do
  it "to #index" do
    expect(get("/dashboard")).to route_to('dashboard/projects#index')
  end

  it "to #issues" do
    expect(get("/dashboard/issues.html")).to route_to('dashboard#issues', format: 'html')
  end

  it "to #calendar_issues" do
    expect(get("/dashboard/issues.ics")).to route_to('dashboard#issues_calendar', format: 'ics')
  end

  it "to #merge_requests" do
    expect(get("/dashboard/merge_requests")).to route_to('dashboard#merge_requests')
  end
end

#                     root        /                                   root#show
describe RootController, 'routing' do
  it 'to #index' do
    expect(get('/')).to route_to('root#index')
  end
end

describe "Authentication", "routing" do
  it "GET /users/sign_in" do
    expect(get("/users/sign_in")).to route_to('sessions#new')
  end

  it "POST /users/sign_in" do
    expect(post("/users/sign_in")).to route_to('sessions#create')
  end

  it "POST /users/sign_out" do
    expect(post("/users/sign_out")).to route_to('sessions#destroy')
  end

  it "POST /users/password" do
    expect(post("/users/password")).to route_to('passwords#create')
  end

  it "GET /users/password/new" do
    expect(get("/users/password/new")).to route_to('passwords#new')
  end

  it "GET /users/password/edit" do
    expect(get("/users/password/edit")).to route_to('passwords#edit')
  end

  it "PUT /users/password" do
    expect(put("/users/password")).to route_to('passwords#update')
  end

  context 'with LDAP configured' do
    include LdapHelpers

    let(:ldap_settings) { { enabled: true } }

    before do
      stub_ldap_setting(ldap_settings)
      Rails.application.reload_routes!
    end

    after(:all) do
      Rails.application.reload_routes!
    end

    it 'POST /users/auth/ldapmain/callback' do
      expect(post("/users/auth/ldapmain/callback")).to route_to('ldap/omniauth_callbacks#ldapmain')
    end

    context 'with LDAP sign-in disabled' do
      let(:ldap_settings) { { enabled: true, prevent_ldap_sign_in: true } }

      it 'prevents POST /users/auth/ldapmain/callback' do
        expect(post("/users/auth/ldapmain/callback")).not_to be_routable
      end
    end
  end
end

describe HealthCheckController, 'routing' do
  it 'to #index' do
    expect(get('/health_check')).to route_to('health_check#index')
  end

  it 'also supports passing checks in the url' do
    expect(get('/health_check/email')).to route_to('health_check#index', checks: 'email')
  end
end
