# frozen_string_literal: true

require 'spec_helper'

# Requires a context with:
# - object
#
RSpec.shared_examples 'blocks unsafe serialization' do
  it 'blocks as_json' do
    expect { object.as_json }.to raise_error(described_class::UnsafeSerializationError, /#{object.class.name}/)
  end

  it 'blocks to_json' do
    expect { object.to_json }.to raise_error(described_class::UnsafeSerializationError, /#{object.class.name}/)
  end
end

RSpec.shared_examples 'allows unsafe serialization' do
  it 'allows as_json' do
    expect { object.as_json }.not_to raise_error
  end

  it 'allows to_json' do
    expect { object.to_json }.not_to raise_error
  end
end
