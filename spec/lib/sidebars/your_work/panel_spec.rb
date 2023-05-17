# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Panel, feature_category: :navigation do
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq({ title: 'Your work', icon: 'work' })
  end
end
