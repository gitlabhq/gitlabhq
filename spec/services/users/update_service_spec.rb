require 'spec_helper'

describe Users::UpdateService do
  let(:user) { create(:user) }

  describe '#execute' do
    it 'updates the name' do
      result = update_user(user, name: 'New Name')

      expect(result).to eq(status: :success)
      expect(user.name).to eq('New Name')
    end

    it 'returns an error result when record cannot be updated' do
      expect do
        update_user(user, { email: 'invalid' })
      end.not_to change { user.reload.email }
    end

    def update_user(user, opts)
      described_class.new(user, opts).execute
    end
  end

  describe '#execute!' do
    it 'updates the name' do
      result = update_user(user, name: 'New Name')

      expect(result).to be true
      expect(user.name).to eq('New Name')
    end

    it 'raises an error when record cannot be updated' do
      expect do
        update_user(user, email: 'invalid')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    def update_user(user, opts)
      described_class.new(user, opts).execute!
    end
  end
end
