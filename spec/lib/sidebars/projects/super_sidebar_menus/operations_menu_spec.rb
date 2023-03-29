# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::OperationsMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Operate"))
    expect(subject.sprite_icon).to eq("deployments")
  end
end
