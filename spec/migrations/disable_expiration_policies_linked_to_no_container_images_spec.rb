# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe DisableExpirationPoliciesLinkedToNoContainerImages do
  let(:projects) { table(:projects) }
  let(:container_expiration_policies) { table(:container_expiration_policies) }
  let(:container_repositories) { table(:container_repositories) }
  let(:namespaces) { table(:namespaces) }

  let!(:namespace) { namespaces.create!(name: 'test', path: 'test') }
  let!(:project) { projects.create!(id: 1, namespace_id: namespace.id, name: 'gitlab1') }
  let!(:container_expiration_policy) { container_expiration_policies.create!(project_id: project.id, enabled: true) }

  before do
    projects.create!(id: 2, namespace_id: namespace.id, name: 'gitlab2')
    container_expiration_policies.create!(project_id: 2, enabled: true)
    container_repositories.create!(id: 1, project_id: 2, name: 'image2')

    projects.create!(id: 3, namespace_id: namespace.id, name: 'gitlab3')
    container_expiration_policies.create!(project_id: 3, enabled: false)
    container_repositories.create!(id: 2, project_id: 3, name: 'image3')
  end

  it 'correctly disable expiration policies linked to no container images' do
    expect(enabled_policies.count).to eq 2
    expect(disabled_policies.count).to eq 1
    expect(container_expiration_policy.enabled).to eq true

    migrate!

    expect(enabled_policies.count).to eq 1
    expect(disabled_policies.count).to eq 2
    expect(container_expiration_policy.reload.enabled).to eq false
  end

  def enabled_policies
    container_expiration_policies.where(enabled: true)
  end

  def disabled_policies
    container_expiration_policies.where(enabled: false)
  end
end
