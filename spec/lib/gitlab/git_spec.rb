require 'spec_helper'

describe Gitlab::Git do
  describe "BLANK_SHA" do
    it "is a string of 40 zero's" do
      expect(Gitlab::Git::BLANK_SHA).to eq('0' * 40)
    end
  end
end
