# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignsRelativePosition do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let(:issues) { table(:issues) }
  let(:designs) { table(:design_management_designs) }

  before do
    issues.create!(id: 1, project_id: project.id)
    issues.create!(id: 2, project_id: project.id)
    issues.create!(id: 3, project_id: project.id)
    issues.create!(id: 4, project_id: project.id)

    designs.create!(id: 1, issue_id: 1, project_id: project.id, filename: 'design1.jpg')
    designs.create!(id: 2, issue_id: 1, project_id: project.id, filename: 'design2.jpg')
    designs.create!(id: 3, issue_id: 2, project_id: project.id, filename: 'design3.jpg')
    designs.create!(id: 4, issue_id: 2, project_id: project.id, filename: 'design4.jpg')
    designs.create!(id: 5, issue_id: 3, project_id: project.id, filename: 'design5.jpg')
  end

  describe '#perform' do
    it 'backfills the position for the designs in each issue' do
      expect(described_class::Design).to receive(:move_nulls_to_start).with(
        a_collection_containing_exactly(
          an_object_having_attributes(id: 1, issue_id: 1),
          an_object_having_attributes(id: 2, issue_id: 1)
        )
      ).ordered.and_call_original

      expect(described_class::Design).to receive(:move_nulls_to_start).with(
        a_collection_containing_exactly(
          an_object_having_attributes(id: 3, issue_id: 2),
          an_object_having_attributes(id: 4, issue_id: 2)
        )
      ).ordered.and_call_original

      # We only expect calls to `move_nulls_to_start` with issues 1 and 2:
      # - Issue 3 should be skipped because we're not passing its ID
      # - Issue 4 should be skipped because it doesn't have any designs
      # - Issue 0 should be skipped because it doesn't exist
      subject.perform([1, 2, 4, 0])

      expect(designs.find(1).relative_position).to be < designs.find(2).relative_position
      expect(designs.find(3).relative_position).to be < designs.find(4).relative_position
      expect(designs.find(5).relative_position).to be_nil
    end
  end
end
