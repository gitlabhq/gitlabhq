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
