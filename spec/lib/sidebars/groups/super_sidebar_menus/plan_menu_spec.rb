# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::SuperSidebarMenus::PlanMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Plan"))
    expect(subject.sprite_icon).to eq("planning")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :group_issue_list,
      :group_epic_list,
      :issue_boards,
      :epic_boards,
      :roadmap,
      :milestones,
      :iterations,
      :group_wiki,
      :crm_contacts
    ])
  end
end
