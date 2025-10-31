# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_delete.html.haml', feature_category: :groups_and_projects do
  let_it_be(:group) { build_stubbed(:group) }

  before do
    allow(view).to receive(:current_user).and_return(double.as_null_object)
  end

  describe 'render' do
    context 'when user can :remove_group' do
      before do
        allow(view).to receive(:can?).with(anything, :remove_group, group).and_return(true)
      end

      it 'enables the Remove group button for a group' do
        @group = group
        render 'groups/settings/delete'

        expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
        expect(rendered).not_to have_selector '[data-button-testid="remove-group-button"].disabled'
        expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
      end
    end

    context 'when user cannot :remove_group' do
      before do
        allow(view).to receive(:can?).with(anything, :remove_group, group).and_return(false)
      end

      it 'disables the Remove group button for a group' do
        @group = group
        output = view.render('groups/settings/delete')

        expect(output).to be_nil
      end
    end
  end
end
