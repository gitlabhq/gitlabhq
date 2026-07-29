# frozen_string_literal: true

RSpec.shared_examples 'a member base cloud event' do
  it 'sets event_category to :members' do
    expect(event.event_category).to eq(:members)
  end

  it 'includes base member source fields in event_data' do
    expect(event.event_data).to include(
      source_id: source.id,
      source_type: source.class.name
    )
  end

  it 'sets the CloudEvent source' do
    expect(event.data[:source]).to eq("#{source.class.name.downcase.pluralize}/#{source.id}")
  end

  it 'sets the CloudEvent subject' do
    expect(event.data[:subject]).to eq("members/#{source.class.name.downcase}/#{source.id}")
  end
end
