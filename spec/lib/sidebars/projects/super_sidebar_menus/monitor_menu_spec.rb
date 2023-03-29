# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::MonitorMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Monitor"))
    expect(subject.sprite_icon).to eq("monitor")
  end
end
