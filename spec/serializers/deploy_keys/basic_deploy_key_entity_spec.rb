# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeys::BasicDeployKeyEntity, feature_category: :continuous_delivery do
  include RequestAwareEntity

  let(:user) { create(:user) }
  let(:project) { create(:project, :internal) }
  let(:project_private) { create(:project, :private) }
  let(:deploy_key) { create(:deploy_key) }
  let(:options) { { user: user } }

  let(:entity) { described_class.new(deploy_key, options) }

  before do
    project.deploy_keys << deploy_key
    project_private.deploy_keys << deploy_key
  end

  describe 'returns deploy keys' do
    let(:expected_result) do
      {
        id: deploy_key.id,
        user_id: deploy_key.user_id,
        title: deploy_key.title,
        fingerprint: deploy_key.fingerprint,
        fingerprint_sha256: deploy_key.fingerprint_sha256,
        destroyed_when_orphaned: true,
        almost_orphaned: false,
        created_at: deploy_key.created_at,
        expires_at: deploy_key.expires_at,
        updated_at: deploy_key.updated_at,
        can_edit: false
      }
    end

    it { expect(entity.as_json).to eq(expected_result) }
  end

  context 'user is an admin' do
    let(:user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { expect(entity.as_json).to include(can_edit: true) }
    end

    context 'when admin mode is disabled' do
      it { expect(entity.as_json).not_to include(can_edit: true) }
    end
  end

  context 'user is a project maintainer' do
    before do
      project.add_maintainer(user)
    end

    context 'project deploy key' do
      let(:options) { { user: user, project: project } }

      it { expect(entity.as_json).to include(can_edit: true) }
      it { expect(entity.as_json).to include(edit_path: edit_project_deploy_key_path(options[:project], deploy_key)) }

      it do
        expect(entity.as_json).to include(enable_path: enable_project_deploy_key_path(options[:project], deploy_key))
      end

      it do
        expect(entity.as_json).to include(disable_path: disable_project_deploy_key_path(options[:project], deploy_key))
      end
    end

    context 'public deploy key' do
      let(:deploy_key_public) { create(:deploy_key, public: true) }
      let(:entity_public) { described_class.new(deploy_key_public, { user: user, project: project }) }

      before do
        project.deploy_keys << deploy_key_public
      end

      it { expect(entity_public.as_json).to include(can_edit: true) }
    end
  end

  describe 'with_owner option' do
    it 'does not return an owner payload when it is set to false' do
      options[:with_owner] = false

      payload = entity.as_json

      expect(payload[:owner]).not_to be_present
    end

    describe 'when with_owner is set to true' do
      before do
        options[:with_owner] = true
      end

      it 'returns an owner payload' do
        payload = entity.as_json

        expect(payload[:owner]).to be_present
        expect(payload[:owner].keys).to include(:id, :name, :username, :avatar_url)
      end

      it 'does not return an owner if current_user cannot read the owner' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(options[:user], :read_user, deploy_key.user).and_return(false)

        payload = entity.as_json

        expect(payload[:owner]).to be_nil
      end
    end
  end

  it 'does not return an owner payload with_owner option not passed in' do
    payload = entity.as_json

    expect(payload[:owner]).not_to be_present
  end
end
