# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Current, feature_category: :cell do
  let_it_be(:current_organization) { create(:organization) }

  after do
    described_class.reset
  end

  describe '.organization=' do
    context 'when organization has not been set yet' do
      where(:value) do
        [nil, ref(:current_organization)]
      end

      with_them do
        it 'assigns the value and locks the organization setter' do
          expect do
            described_class.organization = value
          end.to change { described_class.organization_assigned }.from(nil).to(true)

          expect(described_class.organization).to eq(value)
        end
      end

      it 'pushes organization to the application context' do
        described_class.organization = current_organization

        expect(Gitlab::ApplicationContext.current)
          .to include('meta.organization_id' => current_organization.id)
      end
    end

    context 'when organization has already been set' do
      it 'assigns the value and locks the organization setter' do
        set_value = '_set_value_'

        described_class.organization = set_value

        expect(described_class.organization_assigned).to be(true)
        expect(described_class.organization).to eq(set_value)

        expect do
          described_class.organization = '_new_value_'
        end.to raise_error(
          Current::OrganizationAlreadyAssignedError,
          'Current.organization has already been set in the current thread and should not be set again.'
        )

        expect(described_class.organization).to eq(set_value)
      end

      context 'when not raise outside of dev/test environments' do
        before do
          stub_rails_env('production')
        end

        it 'returns silently without changing value' do
          set_value = '_set_value_'

          described_class.organization = set_value

          expect { described_class.organization = '_new_value_' }.not_to raise_error

          expect(described_class.organization).to eq(set_value)
        end
      end
    end
  end

  describe '.organization_id' do
    subject(:organization_id) { described_class.organization_id }

    context 'when organization is set' do
      before do
        described_class.organization = current_organization
      end

      it 'returns the id of the organization' do
        expect(organization_id).not_to be_nil
        expect(organization_id).to eq(current_organization.id)
      end
    end

    context 'when organization is nil' do
      before do
        described_class.organization = nil
      end

      it 'returns nil' do
        expect(organization_id).to be_nil
      end
    end
  end

  describe '.organization' do
    subject(:assigned_organization) { described_class.organization }

    context 'when organization is not assigned' do
      it 'raises an error' do
        expect { assigned_organization }.to raise_error(
          Current::OrganizationNotAssignedError,
          'Assign an organization to Current.organization before calling it.'
        )
      end

      context 'and environment is production' do
        before do
          stub_rails_env('production')
        end

        it 'returns nil' do
          expect(assigned_organization).to be_nil
        end
      end
    end

    context 'when organization is assigned' do
      before do
        described_class.organization = current_organization
      end

      it 'returns assigned organization' do
        expect(assigned_organization).to eq(current_organization)
      end

      it 'triggers FallbackOrganizationTracker' do
        expect(Gitlab::Organizations::FallbackOrganizationTracker).to receive(:trigger).and_call_original

        assigned_organization
      end
    end
  end
end
