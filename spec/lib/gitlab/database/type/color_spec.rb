# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Database::Type::Color do
  subject(:type) { described_class.new }

  let(:color) { ::Gitlab::Color.of('red') }

  it 'serializes by calling #to_s' do
    expect(type.serialize(color)).to eq(color.to_s)
  end

  it 'serializes nil to nil' do
    expect(type.serialize(nil)).to be_nil
  end

  it 'casts by calling Color::new' do
    expect(type.cast('#fff')).to eq(::Gitlab::Color.new('#fff'))
  end

  it 'accepts colors as arguments to cast' do
    expect(type.cast(color)).to eq(color)
  end

  it 'allows nil database values' do
    expect(type.cast(nil)).to be_nil
  end

  it 'tells us what is serializable' do
    [nil, 'foo', color].each do |value|
      expect(type.serializable?(value)).to be true
    end
  end

  it 'tells us what is not serializable' do
    [0, 3.2, true, Time.current, { some: 'hash' }].each do |value|
      expect(type.serializable?(value)).to be false
    end
  end
end
