# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateGroupPendingBuildService, '#execute', feature_category: :continuous_integration do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:parent_group_project) { create(:project, namespace: parent_group) }
  let_it_be(:child_group) { create(:group, parent: parent_group) }
  let_it_be(:child_group_project) { create(:project, namespace: child_group) }
  let_it_be_with_reload(:pending_build_1) do
    create(:ci_pending_build, project: parent_group_project, instance_runners_enabled: false)
  end

  let_it_be_with_reload(:pending_build_2) do
    create(:ci_pending_build, project: child_group_project, instance_runners_enabled: true)
  end

  let(:update_params) { { instance_runners_enabled: true } }
  let(:service) { described_class.new(group, update_params) }

  subject(:update_pending_builds) { service.execute }

  describe 'validations' do
    context 'when params is invalid' do
      let(:group) { parent_group }
      let(:update_params) { { minutes_exceeded: true } }

      it 'raises an error' do
        expect { update_pending_builds }.to raise_error(Ci::UpdatePendingBuildService::InvalidParamsError)
      end
    end
  end

  context 'when group has pending builds' do
    let(:group) { child_group }

    it 'updates its pending builds', :aggregate_failures do
      update_pending_builds

      expect(pending_build_1.instance_runners_enabled).to be_falsey
      expect(pending_build_2.instance_runners_enabled).to be_truthy
    end
  end

  context 'when group has subgroup with pending builds' do
    let(:group) { parent_group }

    it 'updates all pending builds', :aggregate_failures do
      update_pending_builds

      expect(pending_build_1.instance_runners_enabled).to be_truthy
      expect(pending_build_2.instance_runners_enabled).to be_truthy
    end

    context 'when transferring group' do
      let_it_be(:new_parent_group) { create(:group) }

      let(:update_params) do
        { instance_runners_enabled: true }.merge(Ci::PendingBuild.namespace_transfer_params(parent_group))
      end

      before do
        parent_group.update!(parent: new_parent_group)
        # reload is called to make sure traversal_ids are reloaded
        parent_group.reload
        child_group.reload
      end

      it 'updates all pending builds with namespace_transfer_params', :aggregate_failures do
        update_pending_builds

        expect(pending_build_1).to match(an_object_having_attributes(
          instance_runners_enabled: true,
          **Ci::PendingBuild.namespace_transfer_params(pending_build_1.project.namespace)
        ))
        expect(pending_build_2).to match(an_object_having_attributes(
          instance_runners_enabled: true,
          **Ci::PendingBuild.namespace_transfer_params(pending_build_2.project.namespace)
        ))
      end
    end
  end
end
