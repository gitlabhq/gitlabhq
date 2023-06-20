# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/projects/_form', feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { build_stubbed(:admin) }
  let_it_be(:project) { build_stubbed(:project) }

  before do
    allow(view).to receive(:current_user).and_return(:admin)
    assign(:project, project)
  end

  describe 'project runner registration setting' do
    where(:runner_registration_enabled, :valid_runner_registrars, :checked, :disabled) do
      true  | ['project'] | true  | false
      false | ['project'] | false | false
      false | ['group']   | false | true
    end

    with_them do
      before do
        allow(project).to receive(:runner_registration_enabled).and_return(runner_registration_enabled)
        stub_application_setting(valid_runner_registrars: valid_runner_registrars)
      end

      it 'renders the checkbox correctly' do
        render

        expect(rendered).to have_field(
          'New project runners can be registered',
          type: 'checkbox',
          checked: checked,
          disabled: disabled
        )
      end
    end
  end
end
