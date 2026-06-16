# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingNamespaceDetails, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }

  let!(:organization) { organizations.create!(name: 'Org 1', path: 'org-1') }

  let!(:namespace_1) do
    namespaces.create!(
      name: 'Namespace 1',
      path: 'namespace-1',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:namespace_2) do
    namespaces.create!(
      name: 'Namespace 2',
      path: 'namespace-2',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:namespace_3) do
    namespaces.create!(
      name: 'Namespace 3',
      path: 'namespace-3',
      type: 'Group',
      organization_id: organization.id
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespace_details.insert({
      namespace_id: namespace_1.id,
      created_at: Time.current,
      updated_at: Time.current
    })
  end

  it 'creates namespace_details for namespaces that are missing them', :aggregate_failures do
    expect(namespace_details.where(namespace_id: namespace_2.id)).not_to exist
    expect(namespace_details.where(namespace_id: namespace_1.id)).to exist
    expect(namespace_details.where(namespace_id: namespace_3.id)).not_to exist

    expect { perform_migration }.to change { namespace_details.count }.from(1).to(3)

    expect(namespace_details.where(namespace_id: namespace_1.id)).to exist
    expect(namespace_details.where(namespace_id: namespace_2.id)).to exist
    expect(namespace_details.where(namespace_id: namespace_3.id)).to exist
  end

  it 'leaves existing namespace_details rows untouched', :aggregate_failures do
    details_1 = namespace_details.find_by(namespace_id: namespace_1.id)
    details_1.update!(description: "Updated Description 1", description_html: "<p>Updated html 1</p>")

    expect(namespace_details.find_by(namespace_id: namespace_2.id)).to be_nil
    expect(namespace_details.find_by(namespace_id: namespace_3.id)).to be_nil

    perform_migration

    details_1 = namespace_details.find_by(namespace_id: namespace_1.id)
    expect(details_1.description).to eq('Updated Description 1')
    expect(details_1.description_html).to eq('<p>Updated html 1</p>')

    expect(namespace_details.find_by(namespace_id: namespace_2.id)).to be_present
    expect(namespace_details.find_by(namespace_id: namespace_3.id)).to be_present
  end
end
