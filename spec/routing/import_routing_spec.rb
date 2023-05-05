# frozen_string_literal: true

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
RSpec.shared_examples 'importer routing' do
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
RSpec.describe Import::GithubController, 'routing', feature_category: :importers do
  it_behaves_like 'importer routing' do
    let(:provider) { 'github' }
    let(:is_realtime) { true }
  end

  it 'to #personal_access_token' do
    expect(post('/import/github/personal_access_token')).to route_to('import/github#personal_access_token')
  end

  it 'to #cancel_all' do
    expect(post('/import/github/cancel_all')).to route_to('import/github#cancel_all')
  end

  it 'to #counts' do
    expect(get('/import/github/counts')).to route_to('import/github#counts')
  end
end

# personal_access_token_import_gitea POST     /import/gitea/personal_access_token(.:format)                                                 import/gitea#personal_access_token
#                status_import_gitea GET      /import/gitea/status(.:format)                                                                import/gitea#status
#      realtime_changes_import_gitea GET      /import/gitea/realtime_changes(.:format)                                                                  import/gitea#jobs
#                       import_gitea POST     /import/gitea(.:format)                                                                       import/gitea#create
#                   new_import_gitea GET      /import/gitea/new(.:format)                                                                   import/gitea#new
RSpec.describe Import::GiteaController, 'routing', feature_category: :importers do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:callback] }
    let(:provider) { 'gitea' }
    let(:is_realtime) { true }
  end

  it 'to #personal_access_token' do
    expect(post('/import/gitea/personal_access_token')).to route_to('import/gitea#personal_access_token')
  end
end

#           status_import_bitbucket GET      /import/bitbucket/status(.:format)                                                             import/bitbucket#status
#         callback_import_bitbucket GET      /import/bitbucket/callback(.:format)                                                           import/bitbucket#callback
# realtime_changes_import_bitbucket GET      /import/bitbucket/realtime_changes(.:format)                                                   import/bitbucket#realtime_changes
#                  import_bitbucket POST     /import/bitbucket(.:format)                                                                    import/bitbucket#create
RSpec.describe Import::BitbucketController, 'routing', feature_category: :importers do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:new] }
    let(:provider) { 'bitbucket' }
    let(:is_realtime) { true }
  end
end

#           status_import_bitbucket_server GET      /import/bitbucket_server/status(.:format)                                               import/bitbucket_server#status
#         callback_import_bitbucket_server GET      /import/bitbucket_server/callback(.:format)                                             import/bitbucket_server#callback
# realtime_changes_import_bitbucket_server GET      /import/bitbucket_server/realtime_changes(.:format)                                     import/bitbucket_server#realtime_changes
#              new_import_bitbucket_server GET      /import/bitbucket_server/new(.:format)                                                  import/bitbucket_server#new
#                  import_bitbucket_server POST     /import/bitbucket_server(.:format)                                                      import/bitbucket_server#create
RSpec.describe Import::BitbucketServerController, 'routing', feature_category: :importers do
  it_behaves_like 'importer routing' do
    let(:provider) { 'bitbucket_server' }
    let(:is_realtime) { true }
  end
end

#           status_import_fogbugz GET      /import/fogbugz/status(.:format)                                                             import/fogbugz#status
#         callback_import_fogbugz POST     /import/fogbugz/callback(.:format)                                                           import/fogbugz#callback
# realtime_changes_import_fogbugz GET      /import/fogbugz/realtime_changes(.:format)                                                   import/fogbugz#realtime_changes
#     new_user_map_import_fogbugz GET      /import/fogbugz/user_map(.:format)                                                           import/fogbugz#new_user_map
#  create_user_map_import_fogbugz POST     /import/fogbugz/user_map(.:format)                                                           import/fogbugz#create_user_map
#                  import_fogbugz POST     /import/fogbugz(.:format)                                                                    import/fogbugz#create
#              new_import_fogbugz GET      /import/fogbugz/new(.:format)                                                                import/fogbugz#new
RSpec.describe Import::FogbugzController, 'routing', feature_category: :importers do
  it_behaves_like 'importer routing' do
    let(:except_actions) { [:callback] }
    let(:provider) { 'fogbugz' }
    let(:is_realtime) { true }
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
RSpec.describe Import::GitlabProjectsController, 'routing', feature_category: :importers do
  it 'to #create' do
    expect(post('/import/gitlab_project')).to route_to('import/gitlab_projects#create')
  end

  it 'to #new' do
    expect(get('/import/gitlab_project/new')).to route_to('import/gitlab_projects#new')
  end
end

# status_import_github_group GET /import/github_group/status(.:format) import/github_groups#status
RSpec.describe Import::GithubGroupsController, 'routing', feature_category: :importers do
  it 'to #status' do
    expect(get('/import/github_group/status')).to route_to('import/github_groups#status')
  end
end
