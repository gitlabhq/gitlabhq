# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::IssuesMenu, feature_category: :navigation do
  include Rails.application.routes.url_helpers

  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject(:menu) { described_class.new(context) }

  it 'has correct pill settings' do
    expect(menu.has_pill?).to be true
    expect(menu.pill_count_field).to eq("assigned_issues")
  end

  describe '#link' do
    context 'when work_items_consolidated_list is disabled' do
      before do
        allow(user).to receive(:work_items_consolidated_list_enabled?).and_return(false)
      end

      it 'returns the issues dashboard path' do
        expect(menu.link).to eq(issues_dashboard_path(assignee_username: user.username))
      end
    end

    context 'when work_items_consolidated_list is enabled' do
      before do
        allow(user).to receive(:work_items_consolidated_list_enabled?).and_return(true)
      end

      it 'returns the work items dashboard path' do
        expect(menu.link).to eq(work_items_dashboard_path(assignee_username: user.username))
      end
    end
  end

  describe '#active_routes' do
    it 'includes both issues and work_items dashboard paths' do
      expect(menu.active_routes).to eq({ path: %w[dashboard#issues dashboard#work_items] })
    end
  end
end
