# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Groups::AutoDevopsService, '#execute' do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:group_params) { { auto_devops_enabled: '0' } }
  let(:service) { described_class.new(group, user, group_params) }

  context 'when user does not have enough privileges' do
    it 'raises exception' do
      group.add_developer(user)

      expect do
        service.execute
      end.to raise_exception(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user has enough privileges' do
    before do
      group.add_owner(user)
    end

    it 'updates group auto devops enabled accordingly' do
      service.execute

      expect(group.auto_devops_enabled).to eq(false)
    end

    context 'when group has projects' do
      it 'reflects changes on projects' do
        project_1 = create(:project, namespace: group)

        service.execute

        expect(project_1).not_to have_auto_devops_implicitly_enabled
      end
    end

    context 'when group has subgroups' do
      it 'reflects changes on subgroups' do
        subgroup_1 = create(:group, parent: group)

        service.execute

        expect(subgroup_1.auto_devops_enabled?).to eq(false)
      end

      context 'when subgroups have projects' do
        it 'reflects changes on projects' do
          subgroup_1 = create(:group, parent: group)
          project_1 = create(:project, namespace: subgroup_1)

          service.execute

          expect(project_1).not_to have_auto_devops_implicitly_enabled
        end
      end
    end
  end
end
