# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/accounts/show', feature_category: :user_profile do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for account deletion' do
    context 'when user can delete profile' do
      before do
        allow(user).to receive(:can_be_removed?).and_return(true)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)

        render
      end

      it 'renders delete button' do
        expect(rendered).to have_css("[data-testid='delete-account-button']")
      end
    end

    context 'when user does not have permissions to delete their own profile' do
      before do
        allow(user).to receive(:can_be_removed?).and_return(true)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(false)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text("You don't have access to delete this user.")
      end
    end

    context 'when user cannot be verified automatically' do
      before do
        allow(user).to receive_messages(can_be_removed?: true, can_remove_self?: false)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(false)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text('GitLab is unable to verify your identity automatically.')
      end
    end

    context 'when user has sole ownership of a group' do
      let_it_be(:group) { build_stubbed(:group) }

      before do
        allow(user).to receive_messages(can_be_removed?: false, solo_owned_groups: [group])
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text('Your account is currently the sole owner in the following:')
      end

      it 'renders group as a link in the list' do
        expect(rendered).to have_text('Groups')
        expect(rendered).to have_link(group.name, href: group.web_url)
      end
    end

    context 'when user has sole ownership of a organization' do
      let_it_be(:organization) { build_stubbed(:organization) }

      before do
        allow(user).to receive_messages(can_be_removed?: false, solo_owned_organizations: [organization])
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)
      end

      context 'when feature flag ui_for_organizations is false' do
        before do
          stub_feature_flags(ui_for_organizations: false)

          render
        end

        it 'does not render delete button' do
          expect(rendered).not_to have_css("[data-testid='delete-account-button']")
        end

        it 'renders correct help text' do
          expect(rendered).to have_text('Your account is currently the sole owner in the following:')
        end

        it 'does not render organization as a link in the list' do
          expect(rendered).not_to have_text('Organizations')
          expect(rendered).not_to have_link(organization.name, href: organization.web_url)
        end
      end

      context 'when feature flag ui_for_organizations is true' do
        before do
          stub_feature_flags(ui_for_organizations: true)

          render
        end

        it 'does not render delete button' do
          expect(rendered).not_to have_css("[data-testid='delete-account-button']")
        end

        it 'renders correct help text' do
          expect(rendered).to have_text('Your account is currently the sole owner in the following:')
        end

        it 'renders organization as a link in the list' do
          expect(rendered).to have_text('Organizations')
          expect(rendered).to have_link(organization.name, href: organization.web_url)
        end
      end
    end
  end
end
