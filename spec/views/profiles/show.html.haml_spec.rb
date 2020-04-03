# frozen_string_literal: true

require 'spec_helper'

describe 'profiles/show' do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
  end

  context 'when the profile page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_field('user_name', with: user.name)
      expect(rendered).to have_field('user_id', with: user.id)
    end
  end

  context 'gitlab.com organization field' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when `:gitlab_employee_badge` feature flag is enabled' do
      context 'and when user has an `@gitlab.com` email address' do
        let(:user) { create(:user, email: 'test@gitlab.com') }

        it 'displays the organization field as `readonly` with a `value` of `GitLab`' do
          render

          expect(rendered).to have_selector('#user_organization[readonly][value="GitLab"]')
        end
      end

      context 'and when a user does not have an `@gitlab.com` email' do
        let(:user) { create(:user, email: 'test@example.com') }

        it 'displays an editable organization field' do
          render

          expect(rendered).to have_selector('#user_organization:not([readonly]):not([value="GitLab"])')
        end
      end
    end

    context 'when `:gitlab_employee_badge` feature flag is disabled' do
      before do
        stub_feature_flags(gitlab_employee_badge: false)
      end

      context 'and when a user has an `@gitlab.com` email' do
        let(:user) { create(:user, email: 'test@gitlab.com') }

        it 'displays an editable organization field' do
          render

          expect(rendered).to have_selector('#user_organization:not([readonly]):not([value="GitLab"])')
        end
      end
    end
  end
end
