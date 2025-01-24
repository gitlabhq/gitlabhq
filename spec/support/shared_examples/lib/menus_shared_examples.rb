# frozen_string_literal: true

RSpec.shared_examples_for 'serializable as super_sidebar_menu_args' do
  let(:extra_attrs) { raise NotImplementedError }

  it 'returns hash with provided attributes' do
    expect(menu.serialize_as_menu_item_args).to eq({
      title: menu.title,
      link: menu.link,
      active_routes: menu.active_routes,
      container_html_options: menu.container_html_options,
      **extra_attrs
    })
  end

  it 'returns hash with an item_id' do
    expect(menu.serialize_as_menu_item_args[:item_id]).not_to be_nil
  end
end

RSpec.shared_examples_for 'not serializable as super_sidebar_menu_args' do
  it 'returns nil' do
    expect(menu.serialize_as_menu_item_args).to be_nil
  end
end

RSpec.shared_examples_for 'a panel instantiable by the anonymous user' do
  it do
    context.instance_variable_set(:@current_user, nil)
    expect(described_class.new(context)).to be_a(described_class)
  end
end

RSpec.shared_examples_for 'a panel with uniquely identifiable menu items' do
  let(:menu_items) do
    subject.instance_variable_get(:@menus)
           .flat_map { |menu| menu.instance_variable_get(:@items) }
  end

  it 'all menu_items have unique item_id' do
    duplicated_ids = menu_items.group_by(&:item_id).reject { |_, v| (v.size < 2) }

    expect(duplicated_ids).to eq({})
  end

  it 'all menu_items have an item_id' do
    items_with_nil_id = menu_items.select { |item| item.item_id.nil? }

    expect(items_with_nil_id).to be_empty
  end
end

RSpec.shared_examples_for 'a panel with all menu_items categorized' do
  let(:uncategorized_menu) do
    subject.instance_variable_get(:@menus)
           .find { |menu| menu.instance_of?(::Sidebars::UncategorizedMenu) }
  end

  it 'has no uncategorized menu_items' do
    uncategorized_menu_items = uncategorized_menu.instance_variable_get(:@items)
    expect(uncategorized_menu_items).to eq([])
  end
end
