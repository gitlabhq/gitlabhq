# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ScopeMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe '#container_html_options' do
    subject { described_class.new(context).container_html_options }

    specify { is_expected.to match(hash_including(class: 'shortcuts-project rspec-project-link')) }
  end
end
