require 'spec_helper'

shared_examples 'default query config' do
  it 'has the start attributes' do
    expect(described_class.start_time_attrs).not_to be_nil
  end

  it 'has the stage attribute' do
    expect(described_class.stage).not_to be_nil
  end

  it 'has the end attributes' do
    expect(described_class.end_time_attrs).not_to be_nil
  end

  it 'has the projection attributes' do
    expect(described_class.projections).not_to be_nil
  end
end
