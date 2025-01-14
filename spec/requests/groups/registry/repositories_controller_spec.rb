# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Registry::RepositoriesController, feature_category: :container_registry do
  let_it_be(:group, reload: true) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_container_registry_config(enabled: true, key: 'spec/fixtures/x509_certificate_pk.key')
    stub_container_registry_tags(repository: :any, tags: [])
    stub_container_registry_info
    group.add_reporter(user)
    login_as(user)
  end

  describe 'GET groups/:group_id/-/container_registries.json' do
    subject do
      get group_container_registries_path(group_id: group)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }

    it 'avoids N+1 queries' do
      project = create(:project, group: group)
      create(:container_repository, project: project)
      endpoint = group_container_registries_path(group, format: :json)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get(endpoint) }

      create_list(:project, 2, group: group).each do |project|
        create_list(:container_repository, 2, project: project)
      end

      expect { get(endpoint) }.not_to exceed_all_query_limit(control)

      # sanity check that response is 200
      expect(response).to have_gitlab_http_status(:ok)
      repositories = json_response
      expect(repositories.count).to eq(5)
    end
  end

  describe 'GET groups/:group_id/-/container_registries/:id' do
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:container_repository) { create(:container_repository, :root, project: project) }

    subject do
      get group_container_registry_path(group, container_repository)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end
end
