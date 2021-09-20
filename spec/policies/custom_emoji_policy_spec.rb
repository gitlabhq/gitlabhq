# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomEmojiPolicy do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:custom_emoji) { create(:custom_emoji, group: group) }

  let(:custom_emoji_permissions) do
    [
      :create_custom_emoji,
      :delete_custom_emoji
    ]
  end

  context 'custom emoji permissions' do
    subject { described_class.new(user, custom_emoji) }

    context 'when user is' do
      context 'a developer' do
        before do
          group.add_developer(user)
        end

        it do
          expect_allowed(:create_custom_emoji)
        end
      end

      context 'is maintainer' do
        before do
          group.add_maintainer(user)
        end

        it do
          expect_allowed(*custom_emoji_permissions)
        end
      end

      context 'is owner' do
        before do
          group.add_owner(user)
        end

        it do
          expect_allowed(*custom_emoji_permissions)
        end
      end

      context 'is developer and emoji creator' do
        before do
          group.add_developer(user)
          custom_emoji.update_attribute(:creator, user)
        end

        it do
          expect_allowed(*custom_emoji_permissions)
        end
      end

      context 'is emoji creator but not a member of the group' do
        before do
          custom_emoji.update_attribute(:creator, user)
        end

        it do
          expect_disallowed(*custom_emoji_permissions)
        end
      end
    end
  end
end
