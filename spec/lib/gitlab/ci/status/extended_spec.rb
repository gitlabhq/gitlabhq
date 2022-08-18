# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Status::Extended do
  it 'requires subclass to implement matcher' do
    expect { described_class.matches?(double, double) }
      .to raise_error(NotImplementedError)
  end
end
