# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/groups/_form', feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { build(:user, :admin) }
  let_it_be(:group) { build(:group, namespace_settings: build(:namespace_settings)) }

  before do
    allow(view).to receive(:current_user).and_return(admin)
    allow(view).to receive(:visibility_level).and_return(group.visibility_level)
    assign(:group, group)
  end

  describe 'group runner registration setting' do
    where(:runner_registration_enabled, :valid_runner_registrars, :checked, :disabled) do
      true  | ['group']   | true  | false
      false | ['group']   | false | false
      false | ['project'] | false | true
    end

    with_them do
      before do
        allow(group).to receive(:runner_registration_enabled?).and_return(runner_registration_enabled)
        stub_application_setting(valid_runner_registrars: valid_runner_registrars)
      end

      it 'renders the checkbox correctly' do
        render

        expect(rendered).to have_field(
          'New group runners can be registered',
          type: 'checkbox',
          checked: checked,
          disabled: disabled
        )
      end
    end
  end
end
