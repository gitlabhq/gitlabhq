# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/edit.html.haml', feature_category: :system_access do
  describe 'Email notifications section' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need database queries here
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:parent_group) { create(:group, owners: user) }
    let_it_be_with_reload(:group) { create(:group, parent: parent_group, owners: user) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let(:form) { instance_double(Gitlab::FormBuilders::GitlabUiFormBuilder) }

    before do
      assign(:group, group)
      allow(view).to receive_messages(
        current_user: user,
        f: form
      )
    end

    it 'renders fields for resource_access_token_notify_inherited' do
      render

      expect(rendered).to have_content(
        _('Expiry notification emails about group and project access tokens within this group should be sent to:')
      )
      expect(rendered).to have_selector('#group_resource_access_token_notify_inherited_true:not([disabled])')
      expect(rendered).to have_selector('#group_resource_access_token_notify_inherited_false:not([disabled])')
      expect(rendered).not_to have_content(
        _('A parent group has selected "Only direct members." It cannot be overridden by this group.')
      )
    end

    context 'when pat_expiry_inherited_members_notification FF is disabled' do
      before do
        stub_feature_flags(pat_expiry_inherited_members_notification: false)
      end

      it 'does not render form' do
        render

        expect(rendered).not_to have_content(
          _('Expiry notification emails about group and project access tokens within this group should be sent to:')
        )
      end
    end

    context 'when parent group has resource_access_token_notify_inherited set to false' do
      before do
        parent_group.namespace_settings.update!(
          resource_access_token_notify_inherited: false,
          lock_resource_access_token_notify_inherited: true
        )
      end

      it 'renders disabled fields' do
        render

        expect(rendered).to have_selector('#group_resource_access_token_notify_inherited_false[disabled]')
        expect(rendered).to have_selector('#group_resource_access_token_notify_inherited_true[disabled]')
        expect(rendered).to have_selector('.js-cascading-settings-lock-tooltip-target')
      end
    end
  end
end
