# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::EnvironmentsAutoDelete, :background_operation, feature_category: :continuous_delivery do
  let(:environments) { table(:environments) }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    table(:namespaces).create!(name: 'test', path: 'test', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:env_to_delete) { create_environment(state: 'stopped', auto_delete_at: 1.day.ago) }
  let!(:env_to_delete_2) { create_environment(state: 'stopped', auto_delete_at: 2.days.ago) }
  let!(:env_available) { create_environment(state: 'available', auto_delete_at: 1.day.ago) }
  let!(:env_no_auto_delete) { create_environment(state: 'stopped', auto_delete_at: nil) }
  let!(:env_future_auto_delete) { create_environment(state: 'stopped', auto_delete_at: 1.day.from_now) }

  let!(:min_cursor) { environments.minimum(:id) }
  let!(:max_cursor) { environments.maximum(:id) }

  let!(:operation) do
    described_class.new(
      min_cursor: [min_cursor],
      max_cursor: [max_cursor],
      batch_table: :environments,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'deletes stopped environments past their auto_delete_at', :aggregate_failures do
    expect { operation.perform }
      .to change { environments.exists?(env_to_delete.id) }.from(true).to(false)
      .and change { environments.exists?(env_to_delete_2.id) }.from(true).to(false)
      .and not_change { environments.exists?(env_available.id) }
      .and not_change { environments.exists?(env_no_auto_delete.id) }
      .and not_change { environments.exists?(env_future_auto_delete.id) }
  end

  it 'only deletes environments matching both conditions' do
    expect { operation.perform }.to change { environments.count }.by(-2)
  end

  private

  def create_environment(state:, auto_delete_at:)
    environments.create!(
      project_id: project.id,
      name: "env-#{SecureRandom.hex(4)}",
      slug: SecureRandom.hex(8),
      state: state,
      auto_delete_at: auto_delete_at
    )
  end
end
