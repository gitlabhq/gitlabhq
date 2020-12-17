# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Graphql::FieldSelection do
  it 'can report on the paths that are selected' do
    selection = described_class.new({
      'foo' => nil,
      'bar' => nil,
      'quux' => {
        'a' => nil,
        'b' => { 'x' => nil, 'y' => nil }
      },
      'qoox' => {
        'q' => nil,
        'r' => { 's' => { 't' => nil } }
      }
    })

    expect(selection.paths).to include(
      %w[foo],
      %w[quux a],
      %w[quux b x],
      %w[qoox r s t]
    )
  end

  it 'can serialize a field selection nicely' do
    selection = described_class.new({
      'foo' => nil,
      'bar' => nil,
      'quux' => {
        'a' => nil,
        'b' => { 'x' => nil, 'y' => nil }
      },
      'qoox' => {
        'q' => nil,
        'r' => { 's' => { 't' => nil } }
      }
    })

    expect(selection.to_s).to eq(<<~FRAG.strip)
    foo
    bar
    quux {
     a
     b {
      x
      y
     }
    }
    qoox {
     q
     r {
      s {
       t
      }
     }
    }
    FRAG
  end
end
