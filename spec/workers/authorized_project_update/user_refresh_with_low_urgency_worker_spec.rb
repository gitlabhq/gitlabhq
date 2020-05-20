# frozen_string_literal: true

require 'spec_helper'

describe AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker do
  it 'is labeled as low urgency' do
    expect(described_class.get_urgency).to eq(:low)
  end

  it_behaves_like "refreshes user's project authorizations"
end
