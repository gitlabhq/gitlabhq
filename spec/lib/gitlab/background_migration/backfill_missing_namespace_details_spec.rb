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
      organization_id: organization.id,
      description: 'Description 1',
      description_html: '<p>Description 1</p>'
    )
  end

  let!(:namespace_2) do
    namespaces.create!(
      name: 'Namespace 2',
      path: 'namespace-2',
      type: 'Group',
      organization_id: organization.id,
      description: 'Description 2',
      description_html: '<p>Description 2</p>'
    )
  end

  let!(:namespace_3) do
    namespaces.create!(
      name: 'Namespace 3',
      path: 'namespace-3',
      type: 'Group',
      organization_id: organization.id,
      description: 'Description 3',
      description_html: '<p>Description 3</p>'
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
    namespace_details.where.not(namespace_id: namespace_1.id).delete_all
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

  it 'copies description fields from namespaces to namespace_details and leaves existing namespace_details unchanged',
    :aggregate_failures do
    details_1 = namespace_details.find_by(namespace_id: namespace_1.id)
    details_1.update!(description: "Updated Description 1", description_html: "<p>Updated html 1</p>")

    details_2 = namespace_details.find_by(namespace_id: namespace_2.id)
    expect(details_2).to be_nil

    details_3 = namespace_details.find_by(namespace_id: namespace_2.id)
    expect(details_3).to be_nil

    perform_migration

    # Migration should have updated details_1 since it exists
    details_1 = namespace_details.find_by(namespace_id: namespace_1.id)
    expect(details_1.description).to eq('Updated Description 1')
    expect(details_1.description_html).to eq('<p>Updated html 1</p>')

    details_2 = namespace_details.find_by(namespace_id: namespace_2.id)
    expect(details_2.description).to eq('Description 2')
    expect(details_2.description_html).to eq('<p>Description 2</p>')

    details_3 = namespace_details.find_by(namespace_id: namespace_3.id)
    expect(details_3.description).to eq('Description 3')
    expect(details_3.description_html).to eq('<p>Description 3</p>')
  end
end
