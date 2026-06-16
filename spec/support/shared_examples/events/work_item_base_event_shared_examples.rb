# frozen_string_literal: true

RSpec.shared_examples 'a work item base event' do
  it 'sets event_category to :work_items' do
    expect(event.event_category).to eq(:work_items)
  end

  it 'includes base work item fields in event_data' do
    expect(event.event_data).to include(
      work_item_id: work_item.id,
      work_item_iid: work_item.iid,
      namespace_id: work_item.namespace_id,
      project_id: work_item.project_id,
      work_item_type: work_item.work_item_type.base_type,
      confidential: work_item.confidential
    )
  end

  it 'sets the CloudEvent source to the project' do
    expect(event.data[:source]).to eq("projects/#{work_item.project.id}")
  end

  it 'sets the CloudEvent subject to the work item' do
    expect(event.data[:subject]).to eq("work_items/#{work_item.id}")
  end
end
