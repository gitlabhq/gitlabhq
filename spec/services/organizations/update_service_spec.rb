# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::UpdateService, feature_category: :cell do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:organization) { create(:organization) }

    let(:current_user) { user }
    let(:name) { 'Name' }
    let(:path) { 'path' }
    let(:description) { nil }
    let(:params) { { name: name, path: path } }

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
      before do
        create(:organization_user, organization: organization, user: current_user)
      end

      shared_examples 'updating an organization' do
        it 'updates the organization' do
          response
          organization.reset

          expect(response).to be_success
          expect(organization.name).to eq(name)
          expect(organization.path).to eq(path)
          expect(organization.description).to eq(description)
        end
      end

      context 'with description' do
        let(:description) { 'Organization description' }
        let(:params) do
          {
            name: name,
            path: path,
            description: description
          }
        end

        it_behaves_like 'updating an organization'
      end

      include_examples 'updating an organization'

      it 'returns an error when the organization is not updated' do
        params[:name] = nil

        expect(response).to be_error
        expect(response.message).to match_array(["Name can't be blank"])
      end
    end
  end
end
