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
        title: project.name,
        avatar: project.avatar_url,
        entity_id: project.id,
        super_sidebar_parent: ::Sidebars::StaticMenu,
        item_id: :project_overview
      }
    end
  end

  describe '#container_html_options' do
    subject { described_class.new(context).container_html_options }

    it { is_expected.to match(hash_including(class: 'shortcuts-project')) }
  end
end
