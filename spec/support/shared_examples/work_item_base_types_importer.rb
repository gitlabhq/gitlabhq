# frozen_string_literal: true

RSpec.shared_examples 'work item base types importer' do
  it 'creates all base work item types' do
    # Fixtures need to run on a pristine DB, but the test suite preloads the base types before(:suite)
    WorkItem::Type.delete_all

    expect { subject }.to change(WorkItem::Type, :count).from(0).to(WorkItem::Type::BASE_TYPES.count)
  end
end
