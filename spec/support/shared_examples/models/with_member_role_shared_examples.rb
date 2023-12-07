# frozen_string_literal: true

RSpec.shared_examples 'model with member role relation' do
  describe 'associations', feature_category: :permissions do
    it { is_expected.to belong_to(:member_role) }
  end

  describe 'validations', feature_category: :permissions do
    before do
      model.member_role = create(:member_role, namespace: model.group, base_access_level: Gitlab::Access::DEVELOPER)
      model[model.base_access_level_attr] = Gitlab::Access::DEVELOPER
      stub_licensed_features(custom_roles: true)
    end

    describe 'validate_member_role_access_level' do
      context 'when no member role is associated' do
        let(:member_role) { nil }

        it { is_expected.to be_valid }
      end

      context 'when the member role base access level matches the default membership role' do
        it { is_expected.to be_valid }
      end

      context 'when the member role base access level does not match the default membership role' do
        before do
          model[model.base_access_level_attr] = Gitlab::Access::GUEST
        end

        it 'is invalid' do
          expect(model).not_to be_valid
          expect(model.errors[:member_role_id]).to include(
            _("the custom role's base access level does not match the current access level")
          )
        end
      end
    end

    describe 'validate_access_level_locked_for_member_role' do
      before do
        model.save!
        model[model.base_access_level_attr] = Gitlab::Access::MAINTAINER
      end

      context 'when no member role is associated' do
        before do
          model.member_role = nil
        end

        it { is_expected.to be_valid }
      end

      context 'when the member role has changed' do
        before do
          member_role = create(:member_role, namespace: model.group, base_access_level: Gitlab::Access::MAINTAINER)
          model.member_role = member_role
        end

        it { is_expected.to be_valid }
      end

      context 'when the member role has not changed' do
        it 'is invalid' do
          expect(model).not_to be_valid
          expect(model.errors[model.base_access_level_attr]).to include(
            _('cannot be changed because of an existing association with a custom role')
          )
        end
      end
    end

    describe 'validate_member_role_belongs_to_same_root_namespace' do
      context 'when no member role is associated' do
        before do
          model.member_role = nil
        end

        it { is_expected.to be_valid }
      end

      context "when the member role namespace is the same as the model's group" do
        it { is_expected.to be_valid }
      end

      context "when the member role namespace is outside the hierarchy of the model's group" do
        before do
          model.group = create(:group)
        end

        it 'is invalid' do
          expect(model).not_to be_valid
        end
      end
    end
  end
end
