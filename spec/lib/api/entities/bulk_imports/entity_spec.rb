# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::Entity, feature_category: :importers do
  let_it_be(:entity) { create(:bulk_import_entity) }

  subject { described_class.new(entity).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :id,
      :bulk_import_id,
      :status,
      :source_full_path,
      :destination_name,
      :destination_slug,
      :destination_namespace,
      :parent_id,
      :namespace_id,
      :project_id,
      :created_at,
      :updated_at,
      :failures,
      :migrate_projects,
      :migrate_memberships,
      :has_failures,
      :stats
    )
  end
end
