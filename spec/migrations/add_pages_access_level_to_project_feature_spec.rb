require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180423204600_add_pages_access_level_to_project_feature.rb')

describe AddPagesAccessLevelToProjectFeature, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:features) { table(:project_features) }
  let!(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab') }
  let!(:first_project) { projects.create(name: 'gitlab1', path: 'gitlab1', namespace_id: namespace.id) }
  let!(:first_project_features) { features.create(project_id: first_project.id) }
  let!(:second_project) { projects.create(name: 'gitlab2', path: 'gitlab2', namespace_id: namespace.id) }
  let!(:second_project_features) { features.create(project_id: second_project.id) }

  it 'correctly migrate pages for old projects to be public' do
    migrate!

    # For old projects pages should be public
    expect(first_project_features.reload.pages_access_level).to eq ProjectFeature::PUBLIC
    expect(second_project_features.reload.pages_access_level).to eq ProjectFeature::PUBLIC
  end

  it 'after migration pages are enabled as default' do
    migrate!

    # For new project default is enabled
    third_project = projects.create(name: 'gitlab3', path: 'gitlab3', namespace_id: namespace.id)
    third_project_features = features.create(project_id: third_project.id)
    expect(third_project_features.reload.pages_access_level).to eq ProjectFeature::ENABLED
  end
end
