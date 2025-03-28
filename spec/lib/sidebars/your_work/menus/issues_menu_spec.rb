# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::IssuesMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject(:menu) { described_class.new(context) }

  it 'has correct pill settings' do
    expect(menu.has_pill?).to be true
    expect(menu.pill_count_field).to eq("assigned_issues")
  end
end
