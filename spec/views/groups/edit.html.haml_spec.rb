# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/edit.html.haml', feature_category: :groups_and_projects do
  include Devise::Test::ControllerHelpers

  before do
    stub_template 'groups/settings/_code_suggestions' => ''
  end

  describe '"Share with group lock" setting' do
    let(:root_owner) { create(:user) }
    let(:root_group) { create(:group) }

    before do
      root_group.add_owner(root_owner)
    end

    shared_examples_for '"Share with group lock" setting' do |checkbox_options|
      it 'has the correct label, help text, and checkbox options' do
        assign(:group, test_group)
        allow(view).to receive(:can?).with(test_user, :admin_group, test_group).and_return(true)
        allow(view).to receive(:can_change_group_visibility_level?).and_return(false)
        allow(view).to receive(:current_user).and_return(test_user)
        expect(view).to receive(:can_change_share_with_group_lock?).and_return(!checkbox_options[:disabled])
        expect(view).to receive(:share_with_group_lock_help_text).and_return('help text here')

        render

        expect(rendered).to have_content("Projects in #{test_group.name} cannot be shared with other groups")
        expect(rendered).to have_content('help text here')
        expect(rendered).to have_field('group_share_with_group_lock', **checkbox_options)
      end
    end

    context 'for a root group' do
      let(:test_group) { root_group }
      let(:test_user) { root_owner }

      it_behaves_like '"Share with group lock" setting', { disabled: false, checked: false }
    end

    context 'for a subgroup' do
      let!(:subgroup) { create(:group, parent: root_group) }
      let(:sub_owner) { create(:user) }
      let(:test_group) { subgroup }

      context 'when the root_group has "Share with group lock" disabled' do
        context 'when the subgroup has "Share with group lock" disabled' do
          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: false }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: false }
          end
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: true }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: true }
          end
        end
      end

      context 'when the root_group has "Share with group lock" enabled' do
        before do
          root_group.update_column(:share_with_group_lock, true)
        end

        context 'when the subgroup has "Share with group lock" disabled (parent overridden)' do
          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: false }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: false }
          end
        end

        context 'when the subgroup has "Share with group lock" enabled (same as parent)' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: false, checked: true }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like '"Share with group lock" setting', { disabled: true, checked: true }
          end
        end
      end
    end
  end

  context 'ip_restriction' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      group.add_owner(user)

      assign(:group, group)
      allow(view).to receive(:current_user) { user }
    end

    context 'prompt user about registration features', :without_license do
      context 'with service ping disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it 'renders a placeholder input with registration features message' do
          render

          expect(rendered).to have_field(:group_disabled_ip_restriction_ranges, disabled: true)
          expect(rendered).to have_content(s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|use this feature') })
          expect(rendered).to have_link(s_('RegistrationFeatures|Registration Features Program'))
        end
      end

      context 'with service ping enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it 'does not render a placeholder input with registration features message' do
          render

          expect(rendered).not_to have_field(:group_disabled_ip_restriction_ranges, disabled: true)
          expect(rendered).not_to have_content(s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|use this feature') })
          expect(rendered).not_to have_link(s_('RegistrationFeatures|Registration Features Program'))
        end
      end
    end
  end

  describe 'Email notifications section' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:parent_group) { create(:group, owners: user) }
    let_it_be_with_reload(:group) { create(:group, parent: parent_group, owners: user) }

    before do
      assign(:group, group)
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'renders fields for token_expiry_notify_inherited' do
      render

      expect(rendered).to have_content(_('Expiry notification emails about group and project access tokens within this group should be sent to:'))
      expect(rendered).to have_selector('#group_token_expiry_notify_inherited_true:not([disabled])')
      expect(rendered).to have_selector('#group_token_expiry_notify_inherited_false:not([disabled])')
      expect(rendered).not_to have_content(_('A parent group has selected "Only direct members." It cannot be overridden by this group.'))
    end

    context 'when pat_expiry_inherited_members_notification FF is disabled' do
      before do
        stub_feature_flags(pat_expiry_inherited_members_notification: false)
      end

      it 'does not render form' do
        render

        expect(rendered).not_to have_content(_('Expiry notification emails about group and project access tokens within this group should be sent to:'))
      end
    end

    context 'when parent group has token_expiry_notify_inherited set to false' do
      before do
        parent_group.namespace_settings.update!(token_expiry_notify_inherited: false)
      end

      it 'renders disabled fields' do
        render

        expect(rendered).to have_selector('#group_token_expiry_notify_inherited_false[disabled]')
        expect(rendered).to have_selector('#group_token_expiry_notify_inherited_true[disabled]')
        expect(rendered).to have_content(_('A parent group has selected "Only direct members." It cannot be overridden by this group.'))
      end
    end
  end
end
