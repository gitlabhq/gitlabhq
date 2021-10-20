# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ScopeMenu do
  let(:group) { build(:group) }
  let(:user) { group.owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  describe '#extra_nav_link_html_options' do
    subject { described_class.new(context).extra_nav_link_html_options }

    specify { is_expected.to match(hash_including(class: 'context-header has-tooltip', title: context.group.name)) }
  end
end
