require 'spec_helper'

describe Users::UpdateService, services: true do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe '#execute' do
    it 'updates the name' do
      result = update_user(user, user, name: 'New Name')
      expect(result).to eq({ status: :success })
      expect(user.name).to eq('New Name')
    end

    context 'when updated by an admin' do
      it 'updates the name' do
        result = update_user(admin, user, name: 'New Name')
        expect(result).to eq({ status: :success })
        expect(user.name).to eq('New Name')
      end
    end

    it 'returns an error result when record cannot be updated' do
      expect do
        update_user(user, create(:user), { name: 'New Name' })
      end.to raise_error Gitlab::Access::AccessDeniedError
    end

    def update_user(current_user, user, opts)
      described_class.new(current_user, user, opts).execute
    end
  end
end
