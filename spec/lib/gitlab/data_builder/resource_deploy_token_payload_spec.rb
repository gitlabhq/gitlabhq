# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::ResourceDeployTokenPayload, feature_category: :continuous_delivery do
  let(:event) { :expiring }
  let(:data) { described_class.build(deploy_token, event, resource, { interval: :seven_days }) }

  shared_examples 'includes standard data' do
    specify do
      expect(data[:object_attributes]).to eq(deploy_token.hook_attrs)
      expect(data[:interval]).to eq(:seven_days)
      expect(data[:object_kind]).to eq('deploy_token')
    end
  end

  context 'when token belongs to a project' do
    let_it_be_with_reload(:resource) { create(:project) }
    let_it_be_with_reload(:project) { resource }
    let_it_be_with_reload(:deploy_token) { create(:deploy_token, :project_type) }

    before_all do
      create(:project_deploy_token, project: resource, deploy_token: deploy_token)
    end

    it_behaves_like 'includes standard data'
    it_behaves_like 'project hook data'

    it 'contains project data' do
      expect(data).to have_key(:project)
      expect(data[:event_name]).to eq('expiring_deploy_token')
    end
  end

  context 'when token belongs to a group' do
    let_it_be_with_reload(:resource) { create(:group) }
    let_it_be_with_reload(:deploy_token) { create(:deploy_token, :group) }
    let_it_be_with_reload(:group_deploy_token) do
      create(:group_deploy_token, group: resource, deploy_token: deploy_token)
    end

    it_behaves_like 'includes standard data'

    it 'contains group data' do
      expect(data[:group]).to eq({
        group_name: resource.name,
        group_path: resource.path,
        group_id: resource.id,
        full_path: resource.full_path
      })
      expect(data[:event_name]).to eq('expiring_deploy_token')
    end
  end

  context 'with unknown event' do
    let_it_be_with_reload(:resource) { create(:project) }
    let_it_be_with_reload(:deploy_token) { create(:deploy_token, :project_type) }
    let(:event) { :unknown }

    before_all do
      create(:project_deploy_token, project: resource, deploy_token: deploy_token)
    end

    it 'returns nil for event_name' do
      expect(data[:event_name]).to be_nil
    end
  end
end
