# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlocksUnsafeSerialization do
  before do
    stub_const('DummyModel', Class.new)
    DummyModel.class_eval do
      include ActiveModel::Serializers::JSON
      include BlocksUnsafeSerialization
    end
  end

  it_behaves_like 'blocks unsafe serialization' do
    let(:object) { DummyModel.new }
  end
end
