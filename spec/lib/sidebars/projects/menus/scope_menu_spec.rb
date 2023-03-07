# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ScopeMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { described_class.new(context) }
    let(:extra_attrs) do
      {
        title: _('Project overview'),
        sprite_icon: 'project',
        super_sidebar_parent: ::Sidebars::StaticMenu,
        item_id: :project_overview
      }
    end
  end

  describe '#container_html_options' do
    subject { described_class.new(context).container_html_options }

    specify { is_expected.to match(hash_including(class: 'shortcuts-project rspec-project-link')) }
  end

  describe '#extra_nav_link_html_options' do
    subject { described_class.new(context).extra_nav_link_html_options }

    specify { is_expected.to match(hash_including(class: 'context-header has-tooltip', title: context.project.name)) }
  end
end
