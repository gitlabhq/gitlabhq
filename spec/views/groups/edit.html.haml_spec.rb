require 'spec_helper'

describe 'groups/edit.html.haml' do
  include Devise::Test::ControllerHelpers

  describe 'Share lock option' do
    let(:root_owner) { create(:user) }
    let(:root_group) { create(:group) }

    before do
      root_group.add_owner(root_owner)
    end

    shared_examples_for 'share lock option' do |checkbox_options|
      it 'should have the correct label, help text, and checkbox options' do
        assign(:group, test_group)
        allow(view).to receive(:can?).with(test_user, :admin_group, test_group).and_return(true)
        allow(view).to receive(:can_change_group_visibility_level?).and_return(false)
        allow(view).to receive(:current_user).and_return(test_user)
        expect(view).to receive(:can_change_share_with_group_lock?).and_return(!checkbox_options[:disabled])
        expect(view).to receive(:share_with_group_lock_help_text).and_return('help text here')

        render

        expect(rendered).to have_content("Prevent sharing a project within #{test_group.name} with other groups")
        expect(rendered).to have_css('.descr', text: 'help text here')
        expect(rendered).to have_field('group_share_with_group_lock', checkbox_options)
      end
    end

    context 'for a root group' do
      let(:test_group) { root_group }
      let(:test_user) { root_owner }

      it_behaves_like 'share lock option', { disabled: false, checked: false }
    end

    context 'for a subgroup', :nested_groups do
      let!(:subgroup) { create(:group, parent: root_group) }
      let(:sub_owner) { create(:user) }
      let(:test_group) { subgroup }

      context 'when the root_group has "Share lock" disabled' do
        context 'when the subgroup has "Share lock" disabled' do
          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: false }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: false }
          end
        end

        context 'when the subgroup has "Share lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: true }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: true }
          end
        end
      end

      context 'when the root_group has "Share lock" enabled' do
        before do
          root_group.update_column(:share_with_group_lock, true)
        end

        context 'when the subgroup has "Share lock" disabled (parent overridden)' do
          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: false }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: false }
          end
        end

        context 'when the subgroup has "Share lock" enabled (same as parent)' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          context 'as the root_owner' do
            let(:test_user) { root_owner }

            it_behaves_like 'share lock option', { disabled: false, checked: true }
          end

          context 'as the sub_owner' do
            let(:test_user) { sub_owner }

            it_behaves_like 'share lock option', { disabled: true, checked: true }
          end
        end
      end
    end
  end
end
