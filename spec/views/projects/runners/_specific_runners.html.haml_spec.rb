# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/runners/specific_runners.html.haml' do
  describe 'render' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    before do
      @project = project
      @assignable_runners = []
      @project_runners = []
      allow(view).to receive(:reset_registration_token_namespace_project_settings_ci_cd_path).and_return('banana_url')
    end

    context 'when project runner registration is allowed' do
      before do
        stub_application_setting(valid_runner_registrars: ['project'])
      end

      it 'enables the Remove project button for a project' do
        render 'projects/runners/specific_runners', project: project

        expect(rendered).to have_selector '#js-install-runner'
        expect(rendered).not_to have_content 'Please contact an admin to register runners.'
      end
    end

    context 'when project runner registration is not allowed' do
      before do
        stub_application_setting(valid_runner_registrars: ['group'])
      end

      it 'does not enable the  the Remove project button for a project' do
        render 'projects/runners/specific_runners', project: project

        expect(rendered).to have_content 'Please contact an admin to register runners.'
        expect(rendered).not_to have_selector '#js-install-runner'
      end
    end
  end
end
