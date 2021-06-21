# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/runners/group_runners.html.haml' do
  describe 'render' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    before do
      @group = group
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:reset_registration_token_group_settings_ci_cd_path).and_return('banana_url')
      allow(view).to receive(:can?).with(user, :admin_pipeline, group).and_return(true)
    end

    context 'when group runner registration is allowed' do
      before do
        stub_application_setting(valid_runner_registrars: ['group'])
      end

      it 'enables the Remove group button for a group' do
        render 'groups/runners/group_runners', group: group

        expect(rendered).to have_selector '#js-install-runner'
        expect(rendered).not_to have_content 'Please contact an admin to register runners.'
      end
    end

    context 'when group runner registration is not allowed' do
      before do
        stub_application_setting(valid_runner_registrars: ['project'])
      end

      it 'does not enable the  the Remove group button for a group' do
        render 'groups/runners/group_runners', group: group

        expect(rendered).to have_content 'Please contact an admin to register runners.'
        expect(rendered).not_to have_selector '#js-install-runner'
      end
    end
  end
end
