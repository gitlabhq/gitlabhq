# frozen_string_literal: true

require 'spec_helper'

describe TrackingHelper do
  describe '#tracking_attrs' do
    it 'returns an empty hash' do
      expect(helper.tracking_attrs('a', 'b', 'c')).to eq({})
    end
  end
end
