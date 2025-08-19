# frozen_string_literal: true

RSpec.shared_examples 'updating personal access token last used', :freeze_time do
  before do
    personal_access_token.reset.update_column(:last_used_at, nil)
  end

  it { expect { subject }.to change { personal_access_token.reset.last_used_at }.from(nil).to(Time.current) }
end
