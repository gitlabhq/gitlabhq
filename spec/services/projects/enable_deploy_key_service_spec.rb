require 'spec_helper'

describe Projects::EnableDeployKeyService, services: true do
  let(:deploy_key)  { create(:deploy_key, public: true) }
  let(:project)     { create(:empty_project) }
  let(:user)        { project.creator}
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

  def service
    Projects::EnableDeployKeyService.new(project, user, params)
  end
end
