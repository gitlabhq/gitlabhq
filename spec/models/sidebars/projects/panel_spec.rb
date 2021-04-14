# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Panel do
  let(:project) { build(:project) }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }

  subject { described_class.new(context) }

  it 'has a scope menu' do
    expect(subject.scope_menu).to be_a(Sidebars::Projects::Menus::Scope::Menu)
  end
end
