require 'spec_helper'

describe EntityDateHelper do
  let(:date_helper_class) { Class.new { include EntityDateHelper }.new }

  it 'converts 0 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(0)).to eq(seconds: 0)
  end

  it 'converts 40 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(40)).to eq(seconds: 40)
  end

  it 'converts 60 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(60)).to eq(mins: 1)
  end

  it 'converts 70 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(70)).to eq(mins: 1, seconds: 10)
  end

  it 'converts 3600 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(3600)).to eq(hours: 1)
  end

  it 'converts 3750 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(3750)).to eq(hours: 1, mins: 2, seconds: 30)
  end

  it 'converts 86400 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(86400)).to eq(days: 1)
  end

  it 'converts 86560 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(86560)).to eq(days: 1, mins: 2, seconds: 40)
  end

  it 'converts 86760 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(99760)).to eq(days: 1, hours: 3, mins: 42, seconds: 40)
  end

  it 'converts 986760 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(986760)).to eq(days: 11, hours: 10, mins: 6)
  end
end
