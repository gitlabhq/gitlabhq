require 'rails_helper'

describe CustomEmoji, type: :model do
  subject { create(:custom_emoji) }

  it { is_expected.to belong_to(:namespace) }
  it { is_expected.to have_db_column(:file) }
  it { is_expected.to validate_exclusion_of(:name).in_array(Gitlab::Emoji.emojis_names) }
  it { is_expected.to validate_length_of(:name).is_at_most(36) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:namespace_id) }

  describe '#expire_cache' do
    it 'expires cache after save' do
      expect_any_instance_of(Namespace).to receive(:invalidate_custom_emoji_cache).once

      create(:custom_emoji)
    end
  end
end
