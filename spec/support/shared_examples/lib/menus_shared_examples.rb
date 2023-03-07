# frozen_string_literal: true

RSpec.shared_examples_for 'pill_count formatted results' do
  let(:count_service) { raise NotImplementedError }

  subject(:pill_count) { menu.pill_count }

  it 'returns all digits for count value under 1000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(999)
    end

    expect(pill_count).to eq('999')
  end

  it 'returns truncated digits for count value over 1000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(2300)
    end

    expect(pill_count).to eq('2.3k')
  end

  it 'returns truncated digits for count value over 10000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(12560)
    end

    expect(pill_count).to eq('12.6k')
  end

  it 'returns truncated digits for count value over 100000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(112560)
    end

    expect(pill_count).to eq('112.6k')
  end
end

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
