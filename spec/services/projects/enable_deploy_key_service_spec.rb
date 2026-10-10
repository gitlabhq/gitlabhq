# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnableDeployKeyService, feature_category: :continuous_delivery do
  let_it_be(:deploy_key) { create(:deploy_key, public: true) }
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_refind(:user) { project.creator }
  let!(:params) { { key_id: deploy_key.id } }

  it 'enables the key' do
    expect do
      service.execute
    end.to change { project.deploy_keys.count }.from(0).to(1)
  end

  context 'trying to add an unaccessable key' do
    let_it_be(:another_key) { create(:deploy_key, public: false) }
    let!(:params) { { key_id: another_key.id } }

    it 'returns nil if the key cannot be added' do
      expect(service.execute).to be_nil
    end
  end

  context 'when the key does not exist' do
    let!(:params) { { key_id: non_existing_record_id } }

    it 'returns nil' do
      expect(service.execute).to be_nil
    end
  end

  context 'when adding a private key from another project the user maintains' do
    let_it_be(:other_project) { create(:project, maintainers: user) }
    let_it_be(:private_key) { create(:deploy_key, public: false) }
    let!(:params) { { key_id: private_key.id } }

    before_all do
      other_project.deploy_keys << private_key
    end

    it 'enables the key' do
      expect(service.execute).to eq(private_key)
    end
  end

  context 'when an instance admin adds a key they cannot otherwise access' do
    let_it_be(:another_key) { create(:deploy_key, public: false, user: create(:user)) }
    let_it_be(:admin) { create(:admin) }
    let(:user) { admin }
    let!(:params) { { key_id: another_key.id } }

    context 'when in admin mode', :enable_admin_mode do
      it 'enables the key' do
        expect(service.execute).to eq(another_key)
      end
    end

    context 'when not in admin mode' do
      it 'returns nil' do
        expect(service.execute).to be_nil
      end
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
