# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::NoCacheHeaders do
  class NoCacheTester
    include Gitlab::NoCacheHeaders
  end

  describe "#no_cache_headers" do
    subject { NoCacheTester.new }

    it "raises a RuntimeError" do
      expect { subject.no_cache_headers }.to raise_error(RuntimeError)
    end
  end
end
