# frozen_string_literal: true

RSpec.shared_examples 'updating personal access token last used', :freeze_time do
  before do
    personal_access_token.reset.update_column(:last_used_at, nil)
  end

  it "updates last_used_at when lease is available" do
    allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
      allow(instance).to receive(:try_obtain).and_return(true)
    end

    expect { subject }.to change { personal_access_token.reset.last_used_at }.from(nil).to(Time.current)
  end

  it "does not update last_used_at when lease is not available" do
    allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
      allow(instance).to receive(:try_obtain).and_return(false)
    end

    expect { subject }.not_to change { personal_access_token.reset.last_used_at }
  end
end
