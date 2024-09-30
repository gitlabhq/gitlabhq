# frozen_string_literal: true

# This shared_example requires the following variables:
# - banned_user
# - ban_reason
# - duplicate_user

RSpec.shared_examples 'bans the duplicate user' do
  specify do
    expect { subject }.to change { duplicate_user.reload.banned? }.from(false).to(true)
  end

  it 'records a custom attribute' do
    expect { subject }.to change { UserCustomAttribute.count }.by(1)
    expect(duplicate_user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY).first.value)
      .to eq(ban_reason)
  end

  it 'logs the event' do
    expect(Gitlab::AppLogger).to receive(:info).with(
      message: "Duplicate user auto-ban",
      reason: ban_reason,
      username: duplicate_user.username.to_s,
      user_id: duplicate_user.id,
      email: duplicate_user.email.to_s,
      triggered_by_banned_user_id: banned_user.id,
      triggered_by_banned_username: banned_user.username
    )

    subject
  end
end

RSpec.shared_examples 'does not ban the duplicate user' do
  specify do
    expect { subject }.not_to change { duplicate_user.reload.banned? }
    expect(duplicate_user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY).first).to be_nil
    expect(Gitlab::AppLogger).not_to receive(:info)
  end
end
