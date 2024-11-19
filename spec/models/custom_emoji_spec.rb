# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomEmoji do
  describe 'Associations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:custom_emoji) }
    it { is_expected.to belong_to(:creator).inverse_of(:created_custom_emoji) }
    it { is_expected.to have_db_column(:file) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_length_of(:name).is_at_most(36) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_db_column(:external) }
  end

  describe 'exclusion of duplicated emoji' do
    let(:group) { create(:group, :private) }

    it 'disallows emoji names of built-in emoji' do
      emoji_name = TanukiEmoji.index.all.sample.name until emoji_name && emoji_name.size < 36
      new_emoji = build(:custom_emoji, name: emoji_name, group: group)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(name: ["#{emoji_name} is already being used for another emoji"])
    end

    it 'disallows very long invalid emoji name without regular expression backtracking issues' do
      new_emoji = build(:custom_emoji, name: ('a' * 10000) + '!', group: group)

      Timeout.timeout(1) do
        expect(new_emoji).not_to be_valid
        expect(new_emoji.errors.messages).to eq(name: ["is too long (maximum is 36 characters)", "is invalid"])
      end
    end

    it 'disallows duplicate custom emoji names within namespace' do
      old_emoji = create(:custom_emoji, group: group)
      new_emoji = build(:custom_emoji, name: old_emoji.name, namespace: old_emoji.namespace, group: group)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(name: ["has already been taken"])
    end

    it 'disallows non http and https file value' do
      emoji = build(:custom_emoji, name: 'new-name', group: group, file: 'ftp://some-url.in')

      expect(emoji).not_to be_valid
      expect(emoji.errors.messages).to eq(file: ["is blocked: Only allowed schemes are http, https"])
    end
  end

  describe '#for_resource' do
    let_it_be(:group) { create(:group) }
    let_it_be(:custom_emoji) { create(:custom_emoji, namespace: group) }

    context 'when group is nil' do
      let_it_be(:group) { nil }

      it { expect(described_class.for_resource(group)).to eq([]) }
    end

    context 'when resource is a project' do
      let_it_be(:project) { create(:project) }

      it { expect(described_class.for_resource(project)).to eq([]) }
    end

    it { expect(described_class.for_resource(group)).to eq([custom_emoji]) }
  end

  describe '#for_namespaces' do
    let_it_be(:group) { create(:group) }
    let_it_be(:custom_emoji) { create(:custom_emoji, namespace: group, name: 'flying_parrot') }

    it { expect(described_class.for_namespaces([group.id])).to eq([custom_emoji]) }

    it "does not add sql injections in the query" do
      query = described_class.for_namespaces(
        ["96 THEN (SELECT 1 FROM pg_sleep(5)  LIMIT 1) ELSE (SELECT 1 FROM pg_sleep(1) LIMIT 1) END  --;"]).to_sql

      expect(query).not_to include("pg_sleep")
    end

    context 'with subgroup' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_emoji) { create(:custom_emoji, namespace: subgroup, name: 'flying_parrot') }

      it { expect(described_class.for_namespaces([subgroup.id, group.id])).to eq([subgroup_emoji]) }
    end
  end

  describe '#url' do
    before do
      stub_asset_proxy_setting(
        enabled: true,
        secret_key: 'shared-secret',
        url: 'https://assets.example.com'
      )
    end

    it 'uses the asset proxy' do
      emoji = build(:custom_emoji, name: 'gitlab', file: "http://example.com/test.png")

      expect(emoji.url).to eq("https://assets.example.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67")
    end
  end
end
