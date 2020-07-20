# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Checksummable do
  describe ".hexdigest" do
    let(:fake_class) do
      Class.new do
        include Checksummable
      end
    end

    it 'returns the SHA256 sum of the file' do
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect(fake_class.hexdigest(__FILE__)).to eq(expected)
    end
  end
end
