# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomAttributes::DestroyService, feature_category: :user_profile do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:key) { 'department' }
  let(:current_user) { admin }

  describe '#execute' do
    subject(:service_response) { described_class.new(resource, current_user: current_user, key: key).execute }

    shared_examples 'custom attributes destroy service' do
      context 'when custom attribute exists' do
        before do
          resource.custom_attributes.create!(key: 'department', value: 'engineering')
        end

        it 'deletes the custom attribute' do
          expect { service_response }.to change { resource.custom_attributes.count }.by(-1)
        end

        it_behaves_like 'returning a success service response'

        it 'returns the deleted custom attribute in the payload', :aggregate_failures do
          payload = service_response.payload[:custom_attribute]

          expect(payload).to have_attributes(
            key: 'department',
            value: 'engineering'
          )
          expect(payload).to be_destroyed
        end
      end

      context 'when custom attribute does not exist' do
        it 'does not change the count' do
          expect { service_response }.not_to change { resource.custom_attributes.count }
        end

        it_behaves_like 'returning an error service response'

        it 'returns an error message' do
          expect(service_response.message).to eq('Custom attribute not found')
        end
      end

      context 'when deleting one of multiple attributes' do
        before do
          resource.custom_attributes.create!(key: 'department', value: 'engineering')
          resource.custom_attributes.create!(key: 'priority', value: 'high')
        end

        it 'only deletes the specified attribute' do
          expect { service_response }.to change { resource.custom_attributes.count }.by(-1)
        end

        it 'leaves other attributes intact' do
          service_response
          resource.reload

          expect(resource.custom_attributes.pluck(:key)).to contain_exactly('priority')
        end
      end
    end

    context 'with a user' do
      let_it_be(:resource) { create(:user) }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(current_user, :delete_custom_attribute, resource).and_return(true)
      end

      it_behaves_like 'custom attributes destroy service'
    end

    context 'with a project', :enable_admin_mode do
      let_it_be(:resource) { create(:project) }

      it_behaves_like 'custom attributes destroy service'
    end

    context 'with a group' do
      let_it_be(:resource) { create(:group) }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(current_user, :delete_custom_attribute, resource).and_return(true)
      end

      it_behaves_like 'custom attributes destroy service'
    end

    context 'with an unsupported resource type' do
      let(:resource) { build(:namespace) }

      subject(:service) { described_class.new(resource, current_user: current_user, key: key) }

      it 'raises an ArgumentError during initialization' do
        expect { service }.to raise_error(ArgumentError, /is not supported\. Allowed types: User, Project, Group/)
      end
    end

    context 'when user is not authorized' do
      let_it_be(:resource) { create(:project) }
      let(:current_user) { user }

      before do
        resource.custom_attributes.create!(key: 'department', value: 'engineering')
      end

      it 'does not delete the custom attribute' do
        expect { service_response }.not_to change { resource.custom_attributes.count }
      end

      it_behaves_like 'returning an error service response'

      it 'returns an authorization error message' do
        expect(service_response.message).to eq('You are not authorized to perform this action')
      end
    end
  end
end
