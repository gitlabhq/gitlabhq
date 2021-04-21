# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ProjectOverview::Menu do
  let(:project) { build(:project) }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }

  subject { described_class.new(context) }

  it 'has the required items' do
    items = subject.instance_variable_get(:@items)

    expect(items[0]).to be_a(Sidebars::Projects::Menus::ProjectOverview::MenuItems::Details)
    expect(items[1]).to be_a(Sidebars::Projects::Menus::ProjectOverview::MenuItems::Activity)
    expect(items[2]).to be_a(Sidebars::Projects::Menus::ProjectOverview::MenuItems::Releases)
  end
end
