# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLink do
  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:work_item_parent).class_name('WorkItem') }
  end
end
