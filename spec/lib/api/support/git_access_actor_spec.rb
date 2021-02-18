# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Support::GitAccessActor do
  let(:user) { nil }
  let(:key) { nil }

  subject { described_class.new(user: user, key: key) }

  describe '.from_params' do
    let(:key) { create(:key) }

    context 'with params that are valid' do
      it 'returns an instance of API::Support::GitAccessActor' do
        params = { key_id: key.id }

        expect(described_class.from_params(params)).to be_instance_of(described_class)
      end
    end

    context 'with params that are invalid' do
      it "returns an instance of #{described_class}" do
        expect(described_class.from_params({})).to be_instance_of(described_class)
      end
    end

    context 'when passing an identifier used gitaly' do
      it 'finds the user based on an identifier' do
        expect(described_class).to receive(:identify).and_call_original
        expect(described_class.from_params(identifier: "key-#{key.id}").user).to eq(key.user)
      end
    end
  end

  describe 'attributes' do
    describe '#user' do
      context 'when initialized with a User' do
        let(:user) { build(:user) }

        it 'returns the User' do
          expect(subject.user).to eq(user)
        end
      end

      context 'when initialized with a Key' do
        let(:user_for_key) { build(:user) }
        let(:key) { create(:key, user: user_for_key) }

        it 'returns the User associated to the Key' do
          expect(subject.user).to eq(user_for_key)
        end
      end
    end
  end

  describe '#key_or_user' do
    context 'when params contains a :key_id' do
      it 'is an instance of Key' do
        key = create(:key)
        params = { key_id: key.id }

        expect(described_class.from_params(params).key_or_user).to eq(key)
      end
    end

    context 'when params contains a :user_id' do
      it 'is an instance of User' do
        user = create(:user)
        params = { user_id: user.id }

        expect(described_class.from_params(params).key_or_user).to eq(user)
      end
    end

    context 'when params contains a :username' do
      it 'is an instance of User (via UserFinder)' do
        user = create(:user)
        params = { username: user.username }

        expect(described_class.from_params(params).key_or_user).to eq(user)
      end
    end
  end

  describe '#username' do
    context 'when initialized with a User' do
      let(:user) { build(:user) }

      it 'returns the username' do
        expect(subject.username).to eq(user.username)
      end
    end

    context 'when initialized with a Key' do
      let(:key) { create(:key, user: user_for_key) }

      context 'that has no User associated' do
        let(:user_for_key) { nil }

        it 'returns nil' do
          expect(subject.username).to be_nil
        end
      end

      context 'that has a User associated' do
        let(:user_for_key) { build(:user) }

        it 'returns the username of the User associated to the Key' do
          expect(subject.username).to eq(user_for_key.username)
        end
      end
    end
  end

  describe '#key_details' do
    context 'when initialized with a User' do
      let(:user) { build(:user) }

      it 'returns an empty Hash' do
        expect(subject.key_details).to eq({})
      end
    end

    context 'when initialized with a Key' do
      let(:key) { create(:key, user: user_for_key) }

      context 'that has no User associated' do
        let(:user_for_key) { nil }

        it 'returns a Hash' do
          expect(subject.key_details).to eq({ gl_key_type: 'key', gl_key_id: key.id })
        end
      end

      context 'that has a User associated' do
        let(:user_for_key) { build(:user) }

        it 'returns a Hash' do
          expect(subject.key_details).to eq({ gl_key_type: 'key', gl_key_id: key.id })
        end
      end
    end

    context 'when initialized with a DeployKey' do
      let(:key) { create(:deploy_key) }

      it 'returns a Hash' do
        expect(subject.key_details).to eq({ gl_key_type: 'deploy_key', gl_key_id: key.id })
      end
    end
  end

  describe '#update_last_used_at!' do
    before do
      stub_feature_flags(disable_ssh_key_used_tracking: false)
    end

    context 'when initialized with a User' do
      let(:user) { build(:user) }

      it 'does nothing' do
        expect(user).not_to receive(:update_last_used_at)

        subject.update_last_used_at!
      end
    end

    context 'when initialized with a Key' do
      let(:key) { create(:key) }

      it 'updates update_last_used_at' do
        expect(key).to receive(:update_last_used_at)

        subject.update_last_used_at!
      end

      it 'does not update `last_used_at` when the functionality is disabled' do
        stub_feature_flags(disable_ssh_key_used_tracking: true)

        expect(key).not_to receive(:update_last_used_at)

        subject.update_last_used_at!
      end
    end
  end
end
