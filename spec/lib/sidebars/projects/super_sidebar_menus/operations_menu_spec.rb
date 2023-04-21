# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::OperationsMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Operate"))
    expect(subject.sprite_icon).to eq("deployments")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :packages_registry,
      :container_registry,
      :kubernetes,
      :terraform_states,
      :infrastructure_registry,
      :activity,
      :google_cloud,
      :aws
    ])
  end
end
