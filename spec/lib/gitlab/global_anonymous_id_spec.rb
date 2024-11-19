# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlobalAnonymousId, feature_category: :code_suggestions do
  let(:user) { build(:user, id: 1) }
  let(:uuid1) { 'abcDEF' }
  let(:uuid2) { 'abcXYZ' }

  describe '.instance_id' do
    it 'is stable for the same UUID' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

      instance_id_1 = described_class.instance_id
      instance_id_2 = described_class.instance_id

      expect(instance_id_1).to be_instance_of(String)
      expect(instance_id_2).to eq(instance_id_1)
    end

    it 'is different across different instance UUIDs' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

      instance_id_1 = described_class.instance_id
      instance_id_2 = described_class.instance_id

      expect(instance_id_1).to be_instance_of(String)
      expect(instance_id_2).to be_instance_of(String)
      expect(instance_id_2).not_to eq(instance_id_1)
    end

    it 'is uuid-not-set if instance UUID is not set' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return(nil)

      instance_id = described_class.instance_id

      expect(instance_id).to eq('uuid-not-set')
    end

    it 'is uuid-not-set if instance UUID is blank' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return('')

      instance_id = described_class.instance_id

      expect(instance_id).to eq('uuid-not-set')
    end
  end

  describe '.user_id' do
    it 'is stable for the same user and instance UUID' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

      user_id_1 = described_class.user_id(user)
      user_id_2 = described_class.user_id(user)

      expect(user_id_1).to be_instance_of(String)
      expect(user_id_2).to eq(user_id_2)
    end

    it 'is different for the same user but different instance UUIDs' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

      user_id_1 = described_class.user_id(user)
      user_id_2 = described_class.user_id(user)

      expect(user_id_1).to be_instance_of(String)
      expect(user_id_2).to be_instance_of(String)
      expect(user_id_2).not_to eq(user_id_1)
    end

    it 'is different for different users but same instance UUID' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

      user_id_1 = described_class.user_id(user)
      user_id_2 = described_class.user_id(build(:user, id: 2))

      expect(user_id_1).to be_instance_of(String)
      expect(user_id_2).to be_instance_of(String)
      expect(user_id_2).not_to eq(user_id_1)
    end

    it 'is different for different users and different instance UUIDs' do
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
      expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

      user_id_1 = described_class.user_id(user)
      user_id_2 = described_class.user_id(build(:user, id: 2))

      expect(user_id_1).to be_instance_of(String)
      expect(user_id_2).to be_instance_of(String)
      expect(user_id_2).not_to eq(user_id_1)
    end

    it 'is unknown if no user given' do
      user_id = described_class.user_id(nil)

      expect(user_id).to eq('unknown')
    end

    it 'raises an error if instance is not a user' do
      expect { described_class.user_id(build(:project, id: 1)) }.to raise_error(ArgumentError)
    end
  end
end
