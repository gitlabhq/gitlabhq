require 'spec_helper'

describe FeatureGate do
  describe 'User' do
    describe '#flipper_id' do
      context 'when user is not persisted' do
        let(:user) { build(:user) }

        it { expect(user.flipper_id).to be_nil }
      end

      context 'when user is persisted' do
        let(:user) { create(:user) }

        it { expect(user.flipper_id).to eq "User:#{user.id}" }
      end
    end
  end
end
