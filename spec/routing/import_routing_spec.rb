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
shared_examples 'importer routing' do
  let(:except_actions) { [] }
  let(:is_realtime) { false }

  before do
    except_actions.push(is_realtime ? :jobs : :realtime_changes)
  end

  it 'to #create' do
    expect(post("/import/#{provider}")).to route_to("import/#{provider}#create") unless except_actions.include?(:create)
  end

  it 'to #new' do
    expect(get("/import/#{provider}/new")).to route_to("import/#{provider}#new") unless except_actions.include?(:new)
  end

  it 'to #status' do
    expect(get("/import/#{provider}/status")).to route_to("import/#{provider}#status") unless except_actions.include?(:status)
  end

  it 'to #callback' do
    expect(get("/import/#{provider}/callback")).to route_to("import/#{provider}#callback") unless except_actions.include?(:callback)
  end

  it 'to #jobs' do
    expect(get("/import/#{provider}/jobs")).to route_to("import/#{provider}#jobs") unless except_actions.include?(:jobs)
  end

  it 'to #realtime_changes' do
    expect(get("/import/#{provider}/realtime_changes")).to route_to("import/#{provider}#realtime_changes") unless except_actions.include?(:realtime_changes)
  end
end

# personal_access_token_import_github POST     /import/github/personal_access_token(.:format)                                                import/github#personal_access_token
#                status_import_github GET      /import/github/status(.:format)                                                               import/github#status
#              callback_import_github GET      /import/github/callback(.:format)                                                             import/github#callback
#      realtime_changes_import_github GET      /import/github/realtime_changes(.:format)                                                                 import/github#jobs
#                       import_github POST     /import/github(.:format)                                                                      import/github#create
#                   new_import_github GET      /import/github/new(.:format)                                                                  import/github#new
describe Import::GithubController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:provider) { 'github' }
    let(:is_realtime) { true }
  end

  it 'to #personal_access_token' do
    expect(post('/import/github/personal_access_token')).to route_to('import/github#personal_access_token')
  end
end

# personal_access_token_import_gitea POST     /import/gitea/personal_access_token(.:format)                                                 import/gitea#personal_access_token
#                status_import_gitea GET      /import/gitea/status(.:format)                                                                import/gitea#status
#      realtime_changes_import_gitea GET      /import/gitea/realtime_changes(.:format)                                                                  import/gitea#jobs
#                       import_gitea POST     /import/gitea(.:format)                                                                       import/gitea#create
#                   new_import_gitea GET      /import/gitea/new(.:format)                                                                   import/gitea#new
describe Import::GiteaController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:callback] }
    let(:provider) { 'gitea' }
    let(:is_realtime) { true }
  end

  it 'to #personal_access_token' do
    expect(post('/import/gitea/personal_access_token')).to route_to('import/gitea#personal_access_token')
  end
end

#   status_import_gitlab GET      /import/gitlab/status(.:format)                                                               import/gitlab#status
# callback_import_gitlab GET      /import/gitlab/callback(.:format)                                                             import/gitlab#callback
#     jobs_import_gitlab GET      /import/gitlab/jobs(.:format)                                                                 import/gitlab#jobs
#          import_gitlab POST     /import/gitlab(.:format)                                                                      import/gitlab#create
describe Import::GitlabController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:new] }
    let(:provider) { 'gitlab' }
  end
end

#   status_import_bitbucket GET      /import/bitbucket/status(.:format)                                                            import/bitbucket#status
# callback_import_bitbucket GET      /import/bitbucket/callback(.:format)                                                          import/bitbucket#callback
#     jobs_import_bitbucket GET      /import/bitbucket/jobs(.:format)                                                              import/bitbucket#jobs
#          import_bitbucket POST     /import/bitbucket(.:format)                                                                   import/bitbucket#create
describe Import::BitbucketController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:new] }
    let(:provider) { 'bitbucket' }
  end
end

#          status_import_google_code GET      /import/google_code/status(.:format)                                                          import/google_code#status
#        callback_import_google_code POST     /import/google_code/callback(.:format)                                                        import/google_code#callback
#            jobs_import_google_code GET      /import/google_code/jobs(.:format)                                                            import/google_code#jobs
#    new_user_map_import_google_code GET      /import/google_code/user_map(.:format)                                                        import/google_code#new_user_map
# create_user_map_import_google_code POST     /import/google_code/user_map(.:format)                                                        import/google_code#create_user_map
#                 import_google_code POST     /import/google_code(.:format)                                                                 import/google_code#create
#             new_import_google_code GET      /import/google_code/new(.:format)                                                             import/google_code#new
describe Import::GoogleCodeController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:callback] }
    let(:provider) { 'google_code' }
  end

  it 'to #callback' do
    expect(post("/import/google_code/callback")).to route_to("import/google_code#callback")
  end

  it 'to #new_user_map' do
    expect(get('/import/google_code/user_map')).to route_to('import/google_code#new_user_map')
  end

  it 'to #create_user_map' do
    expect(post('/import/google_code/user_map')).to route_to('import/google_code#create_user_map')
  end
end

#          status_import_fogbugz GET      /import/fogbugz/status(.:format)                                                              import/fogbugz#status
#        callback_import_fogbugz POST     /import/fogbugz/callback(.:format)                                                            import/fogbugz#callback
#            jobs_import_fogbugz GET      /import/fogbugz/jobs(.:format)                                                                import/fogbugz#jobs
#    new_user_map_import_fogbugz GET      /import/fogbugz/user_map(.:format)                                                            import/fogbugz#new_user_map
# create_user_map_import_fogbugz POST     /import/fogbugz/user_map(.:format)                                                            import/fogbugz#create_user_map
#                 import_fogbugz POST     /import/fogbugz(.:format)                                                                     import/fogbugz#create
#             new_import_fogbugz GET      /import/fogbugz/new(.:format)                                                                 import/fogbugz#new
describe Import::FogbugzController, 'routing' do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:callback] }
    let(:provider) { 'fogbugz' }
  end

  it 'to #callback' do
    expect(post("/import/fogbugz/callback")).to route_to("import/fogbugz#callback")
  end

  it 'to #new_user_map' do
    expect(get('/import/fogbugz/user_map')).to route_to('import/fogbugz#new_user_map')
  end

  it 'to #create_user_map' do
    expect(post('/import/fogbugz/user_map')).to route_to('import/fogbugz#create_user_map')
  end
end

#     import_gitlab_project POST     /import/gitlab_project(.:format)                                                              import/gitlab_projects#create
#                           POST     /import/gitlab_project(.:format)                                                              import/gitlab_projects#create
# new_import_gitlab_project GET      /import/gitlab_project/new(.:format)                                                          import/gitlab_projects#new
describe Import::GitlabProjectsController, 'routing' do
  it 'to #create' do
    expect(post('/import/gitlab_project')).to route_to('import/gitlab_projects#create')
  end

  it 'to #new' do
    expect(get('/import/gitlab_project/new')).to route_to('import/gitlab_projects#new')
  end
end

# new_import_phabricator GET  /import/phabricator/new(.:format) import/phabricator#new
# import_phabricator     POST /import/phabricator(.:format)     import/phabricator#create
describe Import::PhabricatorController, 'routing' do
  it 'to #create' do
    expect(post("/import/phabricator")).to route_to("import/phabricator#create")
  end

  it 'to #new' do
    expect(get("/import/phabricator/new")).to route_to("import/phabricator#new")
  end
end
