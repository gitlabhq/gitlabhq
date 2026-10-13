# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillOrbitNamespaceEnrollmentsBeta, feature_category: :knowledge_graph do
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:enabled_namespaces) { table(:knowledge_graph_enabled_namespaces) }
  let(:enrollments) { table(:orbit_namespace_enrollments) }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:enabled_group) { create_namespace('enabled', 'Group') }
  let!(:trial_group) { create_namespace('trial', 'Group') }
  let!(:other_group) { create_namespace('other', 'Group') }
  let!(:user_namespace) { create_namespace('user', 'User') }

  before do
    enabled_namespaces.create!(root_namespace_id: enabled_group.id)
    enabled_namespaces.create!(root_namespace_id: trial_group.id)
    enabled_namespaces.create!(root_namespace_id: user_namespace.id)
    enrollments.create!(namespace_id: trial_group.id, source: 2)
  end

  it 'records beta only for top-level groups with Orbit on, and keeps trial rows' do
    migrate!

    expect(enrollments.pluck(:namespace_id, :source))
      .to contain_exactly([enabled_group.id, 1], [trial_group.id, 2])
  end

  def create_namespace(path, type)
    namespaces.create!(name: path, path: path, type: type, organization_id: organization.id)
  end
end
