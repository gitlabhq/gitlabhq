# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::ProjectO11ySetting, feature_category: :observability do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  describe 'relations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
  end

  describe 'validations' do
    subject(:project_o11y_setting) { build(:observability_project_o11y_setting, project: project, namespace: group) }

    it { is_expected.to validate_uniqueness_of(:project_id) }

    context 'when namespace is own ancestor' do
      let_it_be(:ancestor_group) { create(:group) }
      let_it_be(:project_in_ancestor) { create(:project, group: ancestor_group) }

      it 'is invalid when pointing to own ancestor', :aggregate_failures do
        setting = build(:observability_project_o11y_setting, project: project_in_ancestor, namespace: ancestor_group)
        expect(setting).to be_invalid
        expect(setting.errors[:namespace_id]).to include(
          'must not be an ancestor of the project (use ancestor walk instead)'
        )
      end

      it 'skips ancestor validation when namespace_id is not changed' do
        # Create a setting that points at an ancestor by bypassing validation,
        # then assert an unrelated update doesn't trigger the ancestor check.
        setting = build(:observability_project_o11y_setting, project: project_in_ancestor, namespace: ancestor_group)
        setting.save!(validate: false)

        setting.enabled = false

        # If the guard didn't work, this would fail with the ancestor error
        expect(setting).to be_valid
      end
    end

    context 'when namespace cannot host observability' do
      it 'is invalid when namespace is a project namespace', :aggregate_failures do
        project_namespace = create(:project).project_namespace
        setting = build(:observability_project_o11y_setting, project: project, namespace: project_namespace)
        expect(setting).to be_invalid
        expect(setting.errors[:namespace_id]).to include('cannot be a project namespace')
      end
    end

    context 'when namespace can host observability' do
      it 'is valid when namespace is a group' do
        setting = build(:observability_project_o11y_setting, project: project, namespace: group)
        expect(setting).to be_valid
      end

      it 'is valid when namespace is a user namespace' do
        user_namespace = create(:user_namespace)
        setting = build(:observability_project_o11y_setting, project: project, namespace: user_namespace)
        expect(setting).to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:enabled_setting) do
        create(:observability_project_o11y_setting, project: project, namespace: group, enabled: true)
      end

      let!(:disabled_setting) { create(:observability_project_o11y_setting, namespace: group, enabled: false) }

      it 'returns only enabled settings' do
        expect(described_class.active).to contain_exactly(enabled_setting)
      end
    end
  end

  describe 'cascade delete' do
    context 'when project is destroyed' do
      let_it_be_with_refind(:cascade_project) { create(:project) }
      let_it_be(:target_group) { create(:group) }
      let!(:setting) do
        create(:observability_project_o11y_setting, project: cascade_project, namespace: target_group)
      end

      it 'deletes the override' do
        cascade_project.destroy!
        expect(described_class.find_by(id: setting.id)).to be_nil
      end
    end

    context 'when target namespace is destroyed' do
      let_it_be(:source_project) { create(:project) }
      let_it_be_with_refind(:cascade_group) { create(:group) }
      let!(:setting) do
        create(:observability_project_o11y_setting, project: source_project, namespace: cascade_group)
      end

      it 'deletes the override' do
        cascade_group.destroy!
        expect(described_class.find_by(id: setting.id)).to be_nil
      end
    end
  end
end
