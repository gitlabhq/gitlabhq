# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectsWorker, feature_category: :permissions do
  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include(
      { if_deduplicated: :reschedule_once, including_scheduled: true }
    )
  end

  it_behaves_like "refreshes user's project authorizations"
end
