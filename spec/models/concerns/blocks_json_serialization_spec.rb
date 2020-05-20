# frozen_string_literal: true

require 'spec_helper'

describe BlocksJsonSerialization do
  before do
    stub_const('DummyModel', Class.new)
    DummyModel.class_eval do
      include BlocksJsonSerialization
    end
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
