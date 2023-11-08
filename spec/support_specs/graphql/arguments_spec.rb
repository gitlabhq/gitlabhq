# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Graphql::Arguments do
  it 'returns a blank string if the arguments are blank' do
    args = described_class.new({})

    expect(args.to_s).to be_blank
  end

  it 'returns a serialized arguments if the arguments are not blank' do
    units = described_class.new({ temp: :CELSIUS, time: :MINUTES })
    args = described_class.new({ temp: 180, time: 45, units: units })

    expect(args.to_s).to eq('temp: 180, time: 45, units: {temp: CELSIUS, time: MINUTES}')
  end

  it 'supports merge with +' do
    lhs = described_class.new({ a: 1, b: 2 })
    rhs = described_class.new({ b: 3, c: 4 })

    expect(lhs + rhs).to eq({ a: 1, b: 3, c: 4 })
  end

  it 'supports merge with + and a string' do
    lhs = described_class.new({ a: 1, b: 2 })
    rhs = 'x: no'

    expect(lhs + rhs).to eq('a: 1, b: 2, x: no')
  end

  it 'supports merge with + and a string when empty' do
    lhs = described_class.new({})
    rhs = 'x: no'

    expect(lhs + rhs).to eq('x: no')
  end

  it 'supports merge with + and an empty string' do
    lhs = described_class.new({ a: 1 })
    rhs = ''

    expect(lhs + rhs).to eq({ a: 1 })
  end

  it 'serializes all values correctly' do
    args = described_class.new({
      array: [1, 2.5, "foo", nil, true, false, :BAR, { power: :on }],
      hash: { a: 1, b: 2, c: 3 },
      int: 42,
      float: 2.7,
      string: %q(he said "no"),
      enum: :OFF,
      null: nil,
      bool_true: true,
      bool_false: false,
      var: ::Graphql::Var.new('x', 'Int')
    })

    expect(args.to_s).to eq([
      %q(array: [1,2.5,"foo",null,true,false,BAR,{power: on}]),
      %q(hash: {a: 1, b: 2, c: 3}),
      'int: 42, float: 2.7',
      %q(string: "he said \\"no\\""),
      'enum: OFF',
      'null: null',
      'boolTrue: true, boolFalse: false',
      'var: $x'
    ].join(', '))
  end
end
