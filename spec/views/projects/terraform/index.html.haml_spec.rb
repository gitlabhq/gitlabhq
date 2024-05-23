# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/terraform/index', feature_category: :infrastructure_as_code do
  let_it_be(:project) { build(:project) }

  context 'when the terraform state exists' do
    before do
      assign(:project, project)
    end

    context 'and can show an alert' do
      it 'shows the `period_in_terraform_state_name_alert` alert' do
        allow(view).to receive(:show_period_in_terraform_state_name_alert?).with(project).and_return(true)

        render

        expect(rendered).to have_selector('.js-period-in-terraform-state-name-alert')
      end
    end

    context 'and can not show an alert' do
      it 'does not show the `period_in_terraform_state_name_alert` alert' do
        allow(view).to receive(:show_period_in_terraform_state_name_alert?).with(project).and_return(false)

        render

        expect(rendered).not_to have_selector('.js-period-in-terraform-state-name-alert')
      end
    end
  end
end
