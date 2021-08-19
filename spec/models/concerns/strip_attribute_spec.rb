# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StripAttribute do
  let(:milestone) { create(:milestone) }

  describe ".strip_attributes!" do
    it { expect(Milestone).to respond_to(:strip_attributes!) }
    it { expect(Milestone.strip_attrs).to include(:title) }
  end

  describe "#strip_attributes!" do
    before do
      milestone.title = '    8.3   '
      milestone.valid?
    end

    it { expect(milestone.title).to eq('8.3') }
  end
end
