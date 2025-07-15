# frozen_string_literal: true

RSpec.shared_examples 'creates work item with widgets from a modal' do |work_item_type, expected_widgets|
  it "creates #{work_item_type} work item with expected widgets", :aggregate_failures do
    select_work_item_type(work_item_type.to_s.capitalize)

    expect_work_item_widgets(expected_widgets)

    fill_work_item_title("#{work_item_type} work item")

    create_work_item_with_type(work_item_type)

    expect(page).to have_link "#{work_item_type} work item"
  end
end

RSpec.shared_examples 'creates work item with widgets from new page' do |work_item_type, expected_widgets|
  it "creates #{work_item_type} work item with expected widgets", :aggregate_failures do
    select_work_item_type(work_item_type.to_s.capitalize)

    expect_work_item_widgets(expected_widgets)

    fill_work_item_title("#{work_item_type} work item")

    create_work_item_with_type(work_item_type)

    expect(page).to have_css('h1', text: "#{work_item_type} work item")
  end
end
