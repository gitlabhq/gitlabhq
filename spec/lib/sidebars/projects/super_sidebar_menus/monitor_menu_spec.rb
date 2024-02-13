# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarMenus::MonitorMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  let(:items) { subject.instance_variable_get(:@items) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Monitor"))
    expect(subject.sprite_icon).to eq("monitor")
  end

  it 'defines list of NilMenuItem placeholders' do
    expect(items.map(&:class).uniq).to eq([Sidebars::NilMenuItem])
    expect(items.map(&:item_id)).to eq([
      :tracing,
      :metrics,
      :logs,
      :error_tracking,
      :alert_management,
      :incidents,
      :on_call_schedules,
      :escalation_policies,
      :service_desk
    ])
  end
end
