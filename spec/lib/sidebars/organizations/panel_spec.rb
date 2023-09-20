# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Panel, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:user) { build(:user) }
  let_it_be(:context) { Sidebars::Context.new(current_user: user, container: organization) }

  subject { described_class.new(context) }

  it 'has a scope menu' do
    expect(subject.scope_menu).to be_a(Sidebars::Organizations::Menus::ScopeMenu)
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
