# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/repository/_default_branch', feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }
  let_it_be(:group) { build(:group) }

  before do
    assign(:group, group)
    assign(:current_user, user)
    allow(view).to receive(:can_update_default_branch_protection?).and_return(true)
    allow(view).to receive(:current_user) { user }
    allow(view).to receive(:group) { group }
  end

  context 'when group default_branch_protection_defaults is empty' do
    before do
      allow(group).to receive(:default_branch_protection).and_return({})
    end

    it 'renders default branch protection defaults correctly' do
      render
      expect(rendered).to render_template(partial: 'groups/settings/_default_branch_protection_defaults')
    end
  end
end
