require 'rails_helper'

describe BlocksJsonSerialization do
  DummyModel = Class.new do
    include BlocksJsonSerialization
  end

  it 'blocks as_json' do
    expect { DummyModel.new.to_json }
      .to raise_error(SecurityError, "JSON serialization has been disabled on DummyModel")
  end

  it 'blocks to_json' do
    expect { DummyModel.new.to_json }
      .to raise_error(SecurityError, "JSON serialization has been disabled on DummyModel")
  end
end
