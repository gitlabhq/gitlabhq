# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::RelationImportTracker, feature_category: :importers do
  subject(:entity) { described_class.new(tracker) }

  let(:tracker) { build(:relation_import_tracker) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'exposes correct attributes' do
      is_expected.to eq(
        id: tracker.id,
        project_path: tracker.project.full_path,
        relation: tracker.relation,
        status: :created,
        created_at: tracker.created_at,
        updated_at: tracker.updated_at
      )
    end
  end
end
