# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::PlanMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Plan"))
    expect(subject.sprite_icon).to eq("planning")
  end
end
