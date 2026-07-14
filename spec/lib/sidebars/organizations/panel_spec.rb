# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Panel, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:user) { build(:user) }
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:context, freeze: false) { Sidebars::Context.new(current_user: user, container: organization) }

  subject { described_class.new(context) }

  it 'has a scope menu' do
    expect(subject.scope_menu).to be_a(Sidebars::Organizations::Menus::ScopeMenu)
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
