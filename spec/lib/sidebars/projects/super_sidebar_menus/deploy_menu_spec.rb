# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::DeployMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Deploy"))
    expect(subject.sprite_icon).to eq("deployments")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :releases,
      :feature_flags,
      :packages_registry,
      :container_registry,
      :google_artifact_registry,
      :harbor_registry,
      :model_registry,
      :ai_agents
    ])
  end
end
