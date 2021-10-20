# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::User do
  let_it_be(:timezone) { 'America/Los_Angeles' }

  let(:user) { create(:user, timezone: timezone) }
  let(:current_user) { create(:user) }
  let(:entity) { described_class.new(user, current_user: current_user) }

  subject { entity.as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(:bio, :location, :public_email, :skype, :linkedin, :twitter, :website_url, :organization, :job_title, :work_information, :pronouns)
  end

  it 'exposes created_at if the current user can read the user profile' do
    allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(true)

    expect(subject).to include(:created_at)
  end

  it 'does not expose created_at if the current user cannot read the user profile' do
    allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(false)

    expect(subject).not_to include(:created_at)
  end

  it 'exposes user as not a bot' do
    expect(subject[:bot]).to be_falsey
  end

  context 'with bot user' do
    let(:user) { create(:user, :security_bot) }

    it 'exposes user as a bot' do
      expect(subject[:bot]).to eq(true)
    end
  end

  it 'exposes local_time' do
    local_time = '2:30 PM'
    expect(entity).to receive(:local_time).with(timezone).and_return(local_time)
    expect(subject[:local_time]).to eq(local_time)
  end
end
