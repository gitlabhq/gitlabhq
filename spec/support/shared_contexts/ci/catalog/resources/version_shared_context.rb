# frozen_string_literal: true

RSpec.shared_context 'when there are catalog resources with versions' do
  let_it_be(:current_user) { create(:user) }

  let_it_be(:project1) { create(:project, :repository, name: 'A') }
  let_it_be(:project2) { create(:project, :repository, name: 'Z') }
  let_it_be(:project3) { create(:project, :repository, name: 'L', description: 'Z') }
  let_it_be_with_reload(:resource1) { create(:ci_catalog_resource, project: project1) }
  let_it_be_with_reload(:resource2) { create(:ci_catalog_resource, project: project2) }
  let_it_be(:resource3) { create(:ci_catalog_resource, project: project3) }

  let_it_be(:release_v1_0) { create(:release, project: project1, tag: 'v1.0', released_at: 4.days.ago) }
  let_it_be(:release_v1_1) { create(:release, project: project1, tag: 'v1.1', released_at: 3.days.ago) }
  let_it_be(:release_v2_0) { create(:release, project: project2, tag: 'v2.0', released_at: 2.days.ago) }
  let_it_be(:release_v2_1) { create(:release, project: project2, tag: 'v2.1', released_at: 1.day.ago) }

  let_it_be(:v1_0) do
    create(:ci_catalog_resource_version, catalog_resource: resource1, release: release_v1_0, created_at: 1.day.ago)
  end

  let_it_be(:v1_1) do
    create(:ci_catalog_resource_version, catalog_resource: resource1, release: release_v1_1, created_at: 2.days.ago)
  end

  let_it_be(:v2_0) do
    create(:ci_catalog_resource_version, catalog_resource: resource2, release: release_v2_0, created_at: 3.days.ago)
  end

  let_it_be(:v2_1) do
    create(:ci_catalog_resource_version, catalog_resource: resource2, release: release_v2_1, created_at: 4.days.ago)
  end
end
