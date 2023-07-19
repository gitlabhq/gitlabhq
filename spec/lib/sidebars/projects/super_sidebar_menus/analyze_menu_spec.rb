# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Analyze"))
    expect(subject.sprite_icon).to eq("chart")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :dashboards_analytics,
      :cycle_analytics,
      :contributors,
      :ci_cd_analytics,
      :repository_analytics,
      :code_review,
      :merge_request_analytics,
      :issues,
      :insights,
      :model_experiments
    ])
  end
end
