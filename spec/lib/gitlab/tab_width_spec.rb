# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::TabWidth, :lib do
  describe '.css_class_for_user' do
    it 'returns default CSS class when user is nil' do
      css_class = described_class.css_class_for_user(nil)

      expect(css_class).to eq('tab-width-8')
    end

    it "returns CSS class for user's tab width", :aggregate_failures do
      [1, 6, 12].each do |i|
        user = double('user', tab_width: i)
        css_class = described_class.css_class_for_user(user)

        expect(css_class).to eq("tab-width-#{i}")
      end
    end

    it 'raises if tab width is out of valid range', :aggregate_failures do
      [0, 13, 'foo', nil].each do |i|
        expect do
          user = double('user', tab_width: i)
          described_class.css_class_for_user(user)
        end.to raise_error(ArgumentError)
      end
    end
  end
end
