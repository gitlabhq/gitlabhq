require 'rails_helper'

describe CustomEmoji, type: :model do
  it { is_expected.to belong_to(:namespace) }
  it { is_expected.to have_db_column(:file) }
  it { is_expected.to validate_exclusion_of(:name).in_array(Gitlab::Emoji.emojis_names) }
end
