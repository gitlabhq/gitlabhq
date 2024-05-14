# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::CreateService, feature_category: :cell do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:current_user) { user }
    let(:params) { attributes_for(:organization).merge(extra_params) }
    let(:avatar_filename) { nil }
    let(:extra_params) { {} }
    let(:created_organization) { response.payload[:organization] }

    subject(:response) { described_class.new(current_user: current_user, params: params).execute }

    context 'when user does not have permission' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(response).to be_error

        expect(response.message).to match_array(
          ['You have insufficient permissions to create organizations'])
      end
    end

    context 'when user has permission' do
      shared_examples 'creating an organization' do
        it 'creates the organization' do
          expect { response }.to change { Organizations::Organization.count }
                                   .and change { Organizations::OrganizationUser.count }.by(1)
          expect(response).to be_success
          expect(created_organization.name).to eq(params[:name])
          expect(created_organization.path).to eq(params[:path])
          expect(created_organization.description).to eq(params[:description])
          expect(created_organization.avatar.filename).to eq(avatar_filename)
          expect(created_organization.owner?(current_user)).to be(true)
        end
      end

      it_behaves_like 'creating an organization'

      context 'with description' do
        let(:description) { 'Organization description' }
        let(:extra_params) { { description: description } }

        it_behaves_like 'creating an organization'
      end

      context 'with avatar' do
        let(:avatar_filename) { 'dk.png' }
        let(:avatar) { fixture_file_upload("spec/fixtures/#{avatar_filename}") }
        let(:extra_params) { { avatar: avatar } }

        it_behaves_like 'creating an organization'
      end

      context 'when the organization is not persisted' do
        let(:extra_params) { { name: nil } }

        it 'returns an error when the organization is not persisted' do
          expect(response).to be_error
          expect(response.message).to match_array(["Name can't be blank"])
        end
      end
    end

    context 'when `allow_organization_creation` FF is disabled' do
      before do
        stub_feature_flags(allow_organization_creation: false)
      end

      it 'returns an error' do
        expect(response).to be_error

        expect(response.message)
          .to match_array(['Feature flag `allow_organization_creation` is not enabled for this user.'])
      end
    end
  end
end
