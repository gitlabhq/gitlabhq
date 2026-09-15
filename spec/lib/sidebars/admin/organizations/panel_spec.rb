# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Organizations::Panel, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:user) { build(:admin) }

  let(:context) do
    Sidebars::Context.new(current_user: user, container: nil, current_organization: organization)
  end

  subject(:panel) { described_class.new(context) }

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(s_('Organization|Organization administration'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns the correct header' do
      expect(panel.super_sidebar_context_header).to eq(s_('Organization|Organization administration'))
    end
  end

  it 'includes the overview menu' do
    expect(panel.instance_variable_get(:@menus).map(&:class))
      .to include(Sidebars::Admin::Organizations::Menus::OverviewMenu)
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
