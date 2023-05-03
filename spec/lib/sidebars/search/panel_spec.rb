# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Search::Panel, feature_category: :navigation do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }
  let(:panel) { described_class.new(context) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(_('Search'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns a hash with the correct title and icon' do
      expected_header = {
        title: 'Search',
        icon: 'search'
      }
      expect(panel.super_sidebar_context_header).to eq(expected_header)
    end
  end
end
