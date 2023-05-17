# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Panel, feature_category: :navigation do
  let_it_be(:user) { build(:admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }
  let(:panel) { described_class.new(context) }

  subject { described_class.new(context) }

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(_('Admin Area'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns a hash with the correct title and icon' do
      expected_header = {
        title: panel.aria_label,
        icon: 'admin'
      }

      expect(panel.super_sidebar_context_header).to eq(expected_header)
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
end
