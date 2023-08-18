# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddLinkedItemsWorkItemWidget, :migration, feature_category: :portfolio_management do
  it_behaves_like 'migration that adds widget to work items definitions', widget_name: 'Linked items' do
    let(:work_item_type_count) { 8 }
  end
end
