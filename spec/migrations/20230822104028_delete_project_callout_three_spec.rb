# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteProjectCalloutThree, feature_category: :groups_and_projects do
  let(:migration) { described_class.new }

  let(:user) { table(:users).create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let(:project_callout) { table(:user_project_callouts) }

  let!(:project_callouts_1) { project_callout.create!(project_id: project.id, user_id: user.id, feature_name: 1) }
  let!(:project_callouts_3) { project_callout.create!(project_id: project.id, user_id: user.id, feature_name: 3) }

  it 'deletes only feature name 3' do
    expect { migrate! }.to change { project_callout.count }.from(2).to(1)
    expect(project_callout.find_by_id(project_callouts_3.id)).to be_nil
  end
end
