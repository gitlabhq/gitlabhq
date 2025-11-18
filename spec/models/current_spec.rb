# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Current, feature_category: :organization do
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

  describe '.cells_claims_leases?' do
    subject(:cells_claims_leases?) { described_class.cells_claims_leases? }

    context 'when value is already set' do
      before do
        described_class.cells_claims_leases = true
      end

      it 'returns the cached value without re-evaluating flags' do
        expect(Gitlab.config.cell).not_to receive(:enabled)
        expect(Feature).not_to receive(:enabled)
        expect(cells_claims_leases?).to be(true)
      end
    end

    context 'when value is not yet set' do
      before do
        allow(Gitlab.config.cell).to receive(:enabled).and_return(cell_enabled)
        stub_feature_flags(cells_unique_claims: feature_enabled)
      end

      where(:cell_enabled, :feature_enabled, :expected_result) do
        [
          [true,  true,  true],
          [true,  false, false],
          [false, true,  false],
          [false, false, false]
        ]
      end

      with_them do
        it 'returns expected result and memoizes the value' do
          expect(cells_claims_leases?).to eq(expected_result)
          expect(Gitlab.config.cell).not_to receive(:enabled)
          expect(Feature).not_to receive(:enabled?)
          expect(described_class.cells_claims_leases?).to eq(expected_result)
        end
      end
    end
  end
end
