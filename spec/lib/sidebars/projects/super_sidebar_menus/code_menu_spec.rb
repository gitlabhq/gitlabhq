# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::CodeMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Code"))
    expect(subject.sprite_icon).to eq("code")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :project_merge_request_list,
      :files,
      :branches,
      :commits,
      :tags,
      :graphs,
      :compare,
      :project_snippets,
      :file_locks
    ])
  end
end
