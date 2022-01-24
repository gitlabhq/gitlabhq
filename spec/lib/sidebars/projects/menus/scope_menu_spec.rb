# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ScopeMenu do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe '#container_html_options' do
    subject { described_class.new(context).container_html_options }

    specify { is_expected.to match(hash_including(class: 'shortcuts-project rspec-project-link')) }
  end

  describe '#extra_nav_link_html_options' do
    subject { described_class.new(context).extra_nav_link_html_options }

    specify { is_expected.to match(hash_including(class: 'context-header has-tooltip', title: context.project.name)) }
  end
end
