# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::UpdateService, feature_category: :cell do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:organization) { create(:organization) }

    let_it_be(:current_user) { user } # due to use in before_all
    let(:name) { 'Name' }
    let(:path) { 'path' }
    let(:description) { nil }
    let(:avatar_filename) { nil }
    let(:params) { { name: name, path: path }.merge(extra_params) }
    let(:extra_params) { {} }
    let(:updated_organization) { response.payload[:organization] }

    subject(:response) do
      described_class.new(organization, current_user: current_user, params: params).execute
    end

    context 'when user does not have permission' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(response).to be_error

        expect(response.message).to match_array(['You have insufficient permissions to update the organization'])
      end
    end

    context 'when user has permission' do
      before_all do
        create(:organization_user, :owner, organization: organization, user: current_user)
      end

      shared_examples 'updating an organization' do
        it 'updates the organization' do
          expect(response).to be_success
          expect(updated_organization.name).to eq(name)
          expect(updated_organization.path).to eq(path)
          expect(updated_organization.description).to eq(description)
          expect(updated_organization.avatar.filename).to eq(avatar_filename)
        end
      end

      context 'with description' do
        let(:description) { 'Organization description' }
        let(:extra_params) { { description: description } }

        it_behaves_like 'updating an organization'
      end

      context 'with avatar' do
        let(:avatar_filename) { 'dk.png' }
        let(:avatar) { fixture_file_upload("spec/fixtures/#{avatar_filename}") }
        let(:extra_params) { { avatar: avatar } }

        it_behaves_like 'updating an organization'
      end

      context 'when avatar is set to nil' do
        let_it_be(:organization_detail) { create(:organization_detail, organization: organization) }
        let(:extra_params) { { avatar: nil } }
        let(:description) { organization_detail.description }

        it_behaves_like 'updating an organization'
      end

      include_examples 'updating an organization'

      context 'when the organization is not updated' do
        let(:extra_params) { { name: nil } }

        it 'returns an error' do
          expect(response).to be_error
          expect(updated_organization).to be_instance_of Organizations::Organization
          expect(response.message).to match_array(["Name can't be blank"])
        end
      end
    end
  end
end
