# frozen_string_literal: true

RSpec.shared_examples 'sets work item parent' do
  it 'leaves the note empty and sets work item parent', :aggregate_failures do
    noteable.reload

    expect(execute(note)).to be_empty

    expect(noteable.valid?).to be_truthy
    expect(noteable.work_item_parent).to eq(parent)
  end
end

RSpec.shared_examples 'adds child work items' do
  it 'leaves the note empty and adds child work items', :aggregate_failures do
    noteable.reload

    expect { expect(execute(note)).to be_empty }.to change { WorkItems::ParentLink.count }.by(2)
    expect(noteable.reload.work_item_children).to match_array(children)
    expect(noteable.valid?).to be_truthy
  end
end
