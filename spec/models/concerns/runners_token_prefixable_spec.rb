# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnersTokenPrefixable do
  before do
    stub_const('DummyModel', Class.new)
    DummyModel.class_eval do
      include RunnersTokenPrefixable
    end
  end

  describe '.runners_token_prefix' do
    subject { DummyModel.new }

    it 'returns RUNNERS_TOKEN_PREFIX' do
      expect(subject.runners_token_prefix).to eq(RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX)
    end
  end
end
