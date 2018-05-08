require 'spec_helper'

describe Projects::DeployKeysController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'todos-project') }
  let(:project2) { create(:project, :internal)}

  before(:all) do
    clean_frontend_fixtures('deploy_keys/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  render_views

  it 'deploy_keys/keys.json' do |example|
    create(:deploy_key, public: true)
    project_key = create(:deploy_key, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCdMHEHyhRjbhEZVddFn6lTWdgEy5Q6Bz4nwGB76xWZI5YT/1WJOMEW+sL5zYd31kk7sd3FJ5L9ft8zWMWrr/iWXQikC2cqZK24H1xy+ZUmrRuJD4qGAaIVoyyzBL+avL+lF8J5lg6YSw8gwJY/lX64/vnJHUlWw2n5BF8IFOWhiw== dummy@gitlab.com')
    internal_key = create(:deploy_key, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNd/UJWhPrpb+b/G5oL109y57yKuCxE+WUGJGYaj7WQKsYRJmLYh1mgjrl+KVyfsWpq4ylOxIfFSnN9xBBFN8mlb0Fma5DC7YsSsibJr3MZ19ZNBprwNcdogET7aW9I0In7Wu5f2KqI6e5W/spJHCy4JVxzVMUvk6Myab0LnJ2iQ== dummy@gitlab.com')
    create(:deploy_keys_project, project: project, deploy_key: project_key)
    create(:deploy_keys_project, project: project2, deploy_key: internal_key)

    get :index,
      namespace_id: project.namespace.to_param,
      project_id: project,
      format: :json

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
