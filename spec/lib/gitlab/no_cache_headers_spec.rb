# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::NoCacheHeaders do
  before do
    stub_const('NoCacheTester', Class.new)
    NoCacheTester.class_eval do
      include Gitlab::NoCacheHeaders
    end
  end

  describe "#no_cache_headers" do
    subject { NoCacheTester.new }

    it "raises a RuntimeError" do
      expect { subject.no_cache_headers }.to raise_error(RuntimeError)
    end
  end
end
