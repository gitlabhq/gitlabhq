# frozen_string_literal: true

# This context generates two catalog resources, each with two releases/versions.
# `resource1` has versions `v1.0` and `v1.1`, with releases that have real commit shas.
# `resource2` has versions `v2.0` and `v2.1`.
RSpec.shared_context 'when there are catalog resources with versions' do
  let_it_be(:current_user) { create(:user) }

  let_it_be(:project1) { create(:project, :custom_repo, files: { 'README.md' => 'Readme 1.0.0' }) }
  let_it_be(:project2) { create(:project, :repository) }

  let_it_be_with_reload(:resource1) { create(:ci_catalog_resource, project: project1) }
  let_it_be_with_reload(:resource2) { create(:ci_catalog_resource, project: project2) }

  let(:v1_0) { resource1.versions.by_name('1.0.0').first }
  let(:v1_1) { resource1.versions.by_name('1.1.0').first }
  let(:v2_0) { resource2.versions.by_name('2.0.0').first }
  let(:v2_1) { resource2.versions.by_name('2.1.0').first }

  before_all do
    project1.repository.create_branch('branch_v1.1', project1.default_branch)

    project1.repository.update_file(
      current_user, 'README.md', 'Readme 1.1.0', message: 'Update readme', branch_name: 'branch_v1.1')

    tag_v1_0 = project1.repository.add_tag(current_user, '1.0.0', project1.default_branch)
    tag_v1_1 = project1.repository.add_tag(current_user, '1.1.0', 'branch_v1.1')

    release_v1_0 = create(:release, project: project1, tag: '1.0.0', released_at: 4.days.ago,
      sha: tag_v1_0.dereferenced_target.sha)
    release_v1_1 = create(:release, project: project1, tag: '1.1.0', released_at: 3.days.ago,
      sha: tag_v1_1.dereferenced_target.sha)

    release_v2_0 = create(:release, project: project2, tag: '2.0.0', released_at: 2.days.ago)
    release_v2_1 = create(:release, project: project2, tag: '2.1.0', released_at: 1.day.ago)

    create(:ci_catalog_resource_version, catalog_resource: resource1, release: release_v1_0, created_at: 1.day.ago)
    create(:ci_catalog_resource_version, catalog_resource: resource1, release: release_v1_1, created_at: 2.days.ago)
    create(:ci_catalog_resource_version, catalog_resource: resource2, release: release_v2_0, created_at: 3.days.ago)
    create(:ci_catalog_resource_version, catalog_resource: resource2, release: release_v2_1, created_at: 4.days.ago)
  end
end
