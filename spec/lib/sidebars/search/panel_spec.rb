# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Search::Panel, feature_category: :navigation do
  let(:current_user) { build_stubbed(:user) }
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }
  let(:panel) { described_class.new(context) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(_('Search results'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns a hash with the correct title and icon' do
      expect(panel.super_sidebar_context_header).to eq(nil)
    end
  end
end
