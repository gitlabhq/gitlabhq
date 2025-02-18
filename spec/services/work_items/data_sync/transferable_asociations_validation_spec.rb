# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate transferable associations', feature_category: :team_planning do
  it 'handles transfer for all work item associations', :aggregate_failures do
    expect(known_transferable_associations.size).to eq(known_transferable_associations.uniq.size), -> do
      duplicate_associations(known_transferable_associations)
    end

    work_item_associations = ::WorkItem.reflect_on_all_associations.map(&:name)
    missing_callbacks = work_item_associations - known_transferable_associations
    missing_work_item_association = known_transferable_associations - work_item_associations

    expect(missing_callbacks).to be_blank, -> do
      missing_transfer_callbacks(missing_callbacks)
    end
    expect(missing_work_item_association).to be_blank, -> do
      missing_work_item_association(missing_work_item_association)
    end
  end
end
