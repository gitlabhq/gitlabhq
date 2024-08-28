# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Placeholders::Membership, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:source_user).class_name('Import::SourceUser') }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }

    it 'is destroyed when source user is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.source_user.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when namespace is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.namespace.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when group is destroyed' do
      placeholder_membership = create(:import_placeholder_membership, :for_group)

      expect { placeholder_membership.group.destroy! }.to change { described_class.count }.by(-1)
    end

    it 'is destroyed when project is destroyed' do
      placeholder_membership = create(:import_placeholder_membership)

      expect { placeholder_membership.project.destroy! }.to change { described_class.count }.by(-1)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:source_user_id) }
    it { is_expected.to validate_presence_of(:namespace_id) }

    describe '#validate_project_or_group_present' do
      let_it_be_with_refind(:placeholder_membership) { create(:import_placeholder_membership) }

      it 'is valid when just project is present' do
        expect(placeholder_membership).to be_valid
      end

      it 'is valid when just group is present' do
        placeholder_membership.project = nil
        placeholder_membership.group = create(:group)

        expect(placeholder_membership).to be_valid
      end

      it 'is invalid when both project and group are blank' do
        placeholder_membership.project = nil

        expect(placeholder_membership).to be_invalid
        expect(placeholder_membership.errors[:base]).to include('one of group_id or project_id must be present')
      end

      it 'is invalid when both project and group are present' do
        placeholder_membership.group = create(:group)

        expect(placeholder_membership).to be_invalid
        expect(placeholder_membership.errors[:base]).to include('one of group_id or project_id must be present')
      end
    end

    describe '#validate_access_level' do
      context 'with a project' do
        let_it_be(:placeholder_membership) { create(:import_placeholder_membership) }

        it 'allows valid access levels for ProjectMember' do
          ProjectMember.access_level_roles.each_value do |access_level|
            placeholder_membership.access_level = access_level

            expect(placeholder_membership).to be_valid
          end
        end

        it 'does not allow invalid access levels for ProjectMember' do
          placeholder_membership.access_level = Gitlab::Access::OWNER

          expect(placeholder_membership).not_to be_valid
          expect(placeholder_membership.errors[:access_level]).to include('is not included in the list')
        end
      end

      context 'with a group' do
        let_it_be(:placeholder_membership) { create(:import_placeholder_membership, :for_group) }

        it 'allows valid access levels for GroupMember' do
          GroupMember.access_level_roles.each_value do |access_level|
            placeholder_membership.access_level = access_level

            expect(placeholder_membership).to be_valid
          end
        end

        it 'does not allow invalid access levels for GroupMember' do
          placeholder_membership.access_level = Gitlab::Access::ADMIN

          expect(placeholder_membership).not_to be_valid
          expect(placeholder_membership.errors[:access_level]).to include('is not included in the list')
        end
      end
    end
  end
end
