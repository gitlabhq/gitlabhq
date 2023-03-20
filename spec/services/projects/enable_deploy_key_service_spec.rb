# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnableDeployKeyService, feature_category: :continuous_delivery do
  let(:deploy_key)  { create(:deploy_key, public: true) }
  let(:project)     { create(:project) }
  let(:user)        { project.creator }
  let!(:params)     { { key_id: deploy_key.id } }

  it 'enables the key' do
    expect do
      service.execute
    end.to change { project.deploy_keys.count }.from(0).to(1)
  end

  context 'trying to add an unaccessable key' do
    let(:another_key) { create(:another_key) }
    let!(:params)     { { key_id: another_key.id } }

    it 'returns nil if the key cannot be added' do
      expect(service.execute).to be nil
    end
  end

  context 'add the same key twice' do
    before do
      project.deploy_keys << deploy_key
    end

    it 'returns existing key' do
      expect(service.execute).to eq(deploy_key)
    end
  end

  def service
    Projects::EnableDeployKeyService.new(project, user, params)
  end
end
