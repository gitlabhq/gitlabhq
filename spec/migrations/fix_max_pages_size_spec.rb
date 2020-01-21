# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20191213120427_fix_max_pages_size.rb')

describe FixMaxPagesSize, :migration do
  let(:application_settings) { table(:application_settings) }
  let!(:default_setting) { application_settings.create! }
  let!(:max_possible_setting) { application_settings.create!(max_pages_size: described_class::MAX_SIZE) }
  let!(:higher_than_maximum_setting) { application_settings.create!(max_pages_size: described_class::MAX_SIZE + 1) }

  it 'correctly updates settings only if needed' do
    migrate!

    expect(default_setting.reload.max_pages_size).to eq(100)
    expect(max_possible_setting.reload.max_pages_size).to eq(described_class::MAX_SIZE)
    expect(higher_than_maximum_setting.reload.max_pages_size).to eq(described_class::MAX_SIZE)
  end
end
