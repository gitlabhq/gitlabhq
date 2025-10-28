# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Groups::TransferWorker, feature_category: :organization do
  let_it_be(:group) { create(:group) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }
  let(:args) do
    {
      'group_id' => group.id,
      'organization_id' => organization.id,
      'current_user_id' => user.id
    }
  end

  describe '#perform' do
    subject(:perform) { worker.perform(args) }

    context 'when all records exist' do
      it 'calls the transfer service' do
        expect_next_instance_of(
          Organizations::Groups::TransferService,
          group: group,
          new_organization: organization,
          current_user: user
        ) do |service|
          expect(service).to receive(:execute)
        end

        perform
      end
    end

    context 'when group does not exist' do
      let(:args) do
        {
          'group_id' => non_existing_record_id,
          'organization_id' => organization.id,
          'current_user_id' => user.id
        }
      end

      it 'does not call the transfer service' do
        expect(Organizations::Groups::TransferService).not_to receive(:new)

        perform
      end

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when organization does not exist' do
      let(:args) do
        {
          'group_id' => group.id,
          'organization_id' => non_existing_record_id,
          'current_user_id' => user.id
        }
      end

      it 'does not call the transfer service' do
        expect(Organizations::Groups::TransferService).not_to receive(:new)

        perform
      end

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      let(:args) do
        {
          'group_id' => group.id,
          'organization_id' => organization.id,
          'current_user_id' => non_existing_record_id
        }
      end

      it 'does not call the transfer service' do
        expect(Organizations::Groups::TransferService).not_to receive(:new)

        perform
      end

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end
  end

  describe 'worker attributes' do
    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'has the correct feature category' do
      expect(described_class.get_feature_category).to eq(:organization)
    end

    it 'has low urgency' do
      expect(described_class.get_urgency).to eq(:low)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [args] }
  end
end
