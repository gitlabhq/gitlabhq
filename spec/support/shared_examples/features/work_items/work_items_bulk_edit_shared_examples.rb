# frozen_string_literal: true

RSpec.shared_examples 'when user bulk assigns labels' do
  it 'assigns single label on an work_item' do
    check_work_items([work_item.title])
    add_labels_on_bulk_edit([feature_label.title])
    click_update_selected

    expect(find_work_item_element(work_item.id)).to have_content 'feature'
  end

  it 'assigns labels on multiple work items' do
    check_work_items([work_item.title, work_item_with_label.title])
    add_labels_on_bulk_edit([wontfix_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item_with_label.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item_with_label.id)).to have_content 'frontend'
    end
  end

  it 'assigns multiple labels on one work item' do
    check_work_items([work_item.title])
    add_labels_on_bulk_edit([wontfix_label.title, frontend_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item.id)).to have_content 'frontend'
    end
  end
end

RSpec.shared_examples 'when user bulk assign labels on mixed work item types' do
  it 'assigns labels on mixed work item types' do
    check_work_items([work_item.title, work_item_2.title])
    add_labels_on_bulk_edit([feature_label.title, wontfix_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item.id)).to have_content 'feature'
      expect(find_work_item_element(work_item_2.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item_2.id)).to have_content 'feature'
    end
  end
end

RSpec.shared_examples 'when user bulk unassigns labels' do
  it 'unassigns single label from one work_item' do
    check_work_items([work_item_with_multiple_labels.title])
    remove_labels_on_bulk_edit([wontfix_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item_with_multiple_labels.id)).not_to have_content 'wontfix'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).to have_content 'frontend'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).to have_content 'feature'
    end
  end

  it 'unassigns multiple labels from one work item' do
    check_work_items([work_item_with_multiple_labels.title])
    remove_labels_on_bulk_edit([wontfix_label.title, frontend_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item_with_multiple_labels.id)).not_to have_content 'wontfix'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).not_to have_content 'frontend'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).to have_content 'feature'
    end
  end

  it 'unassigns labels from multiple work items' do
    check_work_items([work_item_with_label.title, work_item_with_multiple_labels.title])
    remove_labels_on_bulk_edit([feature_label.title, frontend_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item_with_label.id)).not_to have_content 'feature'
      expect(find_work_item_element(work_item_with_label.id)).not_to have_content 'frontend'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).not_to have_content 'frontend'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).not_to have_content 'feature'
      expect(find_work_item_element(work_item_with_multiple_labels.id)).to have_content 'wontfix'
    end
  end
end

RSpec.shared_examples 'when user bulk assigns and unassigns labels simultaneously' do
  it 'processes both operations correctly' do
    check_work_items([work_item.title, work_item_with_label.title])
    add_labels_on_bulk_edit([wontfix_label.title, feature_label.title])
    remove_labels_on_bulk_edit([frontend_label.title])
    click_update_selected

    aggregate_failures do
      expect(find_work_item_element(work_item.id)).not_to have_content 'frontend'
      expect(find_work_item_element(work_item.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item.id)).to have_content 'feature'
      expect(find_work_item_element(work_item_with_label.id)).not_to have_content 'frontend'
      expect(find_work_item_element(work_item_with_label.id)).to have_content 'wontfix'
      expect(find_work_item_element(work_item_with_label.id)).to have_content 'feature'
    end
  end
end
