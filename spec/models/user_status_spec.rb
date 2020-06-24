# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserStatus do
  it { is_expected.to validate_presence_of(:user) }

  it { is_expected.to allow_value('smirk').for(:emoji) }
  it { is_expected.not_to allow_value('hello world').for(:emoji) }
  it { is_expected.not_to allow_value('').for(:emoji) }

  it { is_expected.to validate_length_of(:message).is_at_most(100) }
  it { is_expected.to allow_value('').for(:message) }

  it 'is expected to be deleted when the user is deleted' do
    status = create(:user_status)

    expect { status.user.destroy }.to change { described_class.count }.from(1).to(0)
  end
end
