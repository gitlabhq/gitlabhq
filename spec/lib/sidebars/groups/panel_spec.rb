# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Panel, feature_category: :navigation do
  let_it_be(:group) { create(:group) }

  let(:context) { Sidebars::Groups::Context.new(current_user: nil, container: group) }

  subject { described_class.new(context) }

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq({ title: group.name, avatar: group.avatar_url, id: group.id })
  end
end
