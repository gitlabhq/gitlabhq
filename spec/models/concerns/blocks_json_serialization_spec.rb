require 'rails_helper'

describe BlocksJsonSerialization do
  DummyModel = Class.new do
    include BlocksJsonSerialization
  end

  it 'blocks as_json' do
    expect { DummyModel.new.as_json }
      .to raise_error(described_class::JsonSerializationError, /DummyModel/)
  end

  it 'blocks to_json' do
    expect { DummyModel.new.to_json }
      .to raise_error(described_class::JsonSerializationError, /DummyModel/)
  end
end
