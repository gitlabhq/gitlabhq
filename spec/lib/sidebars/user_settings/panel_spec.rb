# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Panel, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(_('User settings'))
  end
end
