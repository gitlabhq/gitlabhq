# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomAttributes::UpsertService, feature_category: :user_profile do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:key) { 'department' }
  let(:value) { 'engineering' }
  let(:current_user) { admin }

  describe '#execute' do
    subject(:service_response) do
      described_class.new(resource, current_user: current_user, key: key, value: value).execute
    end

    shared_examples 'custom attributes upsert service' do
      context 'when user is not authorized' do
        let(:current_user) { user }

        it 'does not create a custom attribute' do
          expect { service_response }.not_to change { resource.custom_attributes.count }
        end

        it 'returns an unauthorized error' do
          expect(service_response).to be_error
          expect(service_response.reason).to eq(:unauthorized)
          expect(service_response.message).to eq('unauthorized')
        end
      end

      context 'when user is an admin', :enable_admin_mode do
        context 'when creating a new custom attribute' do
          it 'creates the custom attribute' do
            expect { service_response }.to change { resource.custom_attributes.count }.by(1)
          end

          it_behaves_like 'returning a success service response'

          it 'returns the custom attribute in the payload', :aggregate_failures do
            expect(service_response.payload[:custom_attribute]).to have_attributes(
              key: key,
              value: value
            )
          end
        end

        context 'when updating an existing custom attribute' do
          before do
            resource.custom_attributes.create!(key: 'department', value: 'old_value')
          end

          it 'does not create a new custom attribute' do
            expect { service_response }.not_to change { resource.custom_attributes.count }
          end

          it 'updates the existing custom attribute value' do
            expect { service_response }
              .to change { resource.custom_attributes.find_by(key: key).value }
              .from('old_value').to(value)
          end

          it_behaves_like 'returning a success service response'

          it 'returns the updated custom attribute' do
            expect(service_response.payload[:custom_attribute].value).to eq(value)
          end
        end

        context 'when validation fails' do
          using RSpec::Parameterized::TableSyntax

          where(:key_value, :value_value, :expected_error) do
            ''           | 'engineering' | "Key can't be blank"
            'department' | ''            | "Value can't be blank"
          end

          with_them do
            let(:key) { key_value }
            let(:value) { value_value }

            it 'does not create a custom attribute' do
              expect { service_response }.not_to change { resource.custom_attributes.count }
            end

            it_behaves_like 'returning an error service response'

            it 'includes the validation error message' do
              expect(service_response.message).to include(expected_error)
            end
          end
        end
      end
    end

    context 'with a user' do
      let_it_be(:resource) { create(:user) }

      it_behaves_like 'custom attributes upsert service'
    end

    context 'with a group' do
      let_it_be(:resource) { create(:group) }

      it_behaves_like 'custom attributes upsert service'
    end

    context 'with a project' do
      let_it_be(:resource) { create(:project) }

      it_behaves_like 'custom attributes upsert service'
    end

    context 'with an unsupported resource type' do
      let(:resource) { build(:namespace) }

      subject(:service) { described_class.new(resource, current_user: admin, key: key, value: value) }

      it 'raises an ArgumentError during initialization' do
        expect { service }.to raise_error(ArgumentError, /is not supported\. Allowed types: User, Project, Group/)
      end
    end
  end
end
