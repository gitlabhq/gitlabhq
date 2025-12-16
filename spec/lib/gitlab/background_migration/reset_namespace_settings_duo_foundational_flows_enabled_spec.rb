# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetNamespaceSettingsDuoFoundationalFlowsEnabled, feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }
  let!(:namespace1) { namespaces.create!(organization_id: organization.id, path: 'one', name: 'One') }
  let!(:namespace2) { namespaces.create!(organization_id: organization.id, path: 'two', name: 'Two') }
  let!(:namespace3) { namespaces.create!(organization_id: organization.id, path: 'three', name: 'Three') }

  let!(:setting_with_false) do
    namespace_settings.create!(namespace_id: namespace1.id, duo_foundational_flows_enabled: false)
  end

  let!(:setting_with_true) do
    namespace_settings.create!(namespace_id: namespace2.id, duo_foundational_flows_enabled: true)
  end

  let!(:setting_with_nil) do
    namespace_settings.create!(namespace_id: namespace3.id, duo_foundational_flows_enabled: nil)
  end

  let(:start_id) { namespace_settings.minimum(:namespace_id) }
  let(:end_id) { namespace_settings.maximum(:namespace_id) }

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'resets all values to nil' do
    expect { migration.perform }
      .to change { setting_with_false.reload.duo_foundational_flows_enabled }
      .from(false).to(nil)
      .and change { setting_with_true.reload.duo_foundational_flows_enabled }
      .from(true).to(nil)
      .and not_change { setting_with_nil.reload.duo_foundational_flows_enabled }
  end
end
