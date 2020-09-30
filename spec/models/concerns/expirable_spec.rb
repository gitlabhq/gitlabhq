# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Expirable do
  describe 'ProjectMember' do
    let_it_be(:no_expire) { create(:project_member) }
    let_it_be(:expire_later) { create(:project_member, expires_at: 8.days.from_now) }
    let_it_be(:expired) { create(:project_member, expires_at: 1.day.from_now) }

    before do
      travel_to(3.days.from_now)
    end

    describe '.expired' do
      it { expect(ProjectMember.expired).to match_array([expired]) }
    end

    describe '#expired?' do
      it { expect(no_expire.expired?).to eq(false) }
      it { expect(expire_later.expired?).to eq(false) }
      it { expect(expired.expired?).to eq(true) }
    end

    describe '#expires?' do
      it { expect(no_expire.expires?).to eq(false) }
      it { expect(expire_later.expires?).to eq(true) }
      it { expect(expired.expires?).to eq(true) }
    end

    describe '#expires_soon?' do
      it { expect(no_expire.expires_soon?).to eq(false) }
      it { expect(expire_later.expires_soon?).to eq(true) }
      it { expect(expired.expires_soon?).to eq(true) }
    end
  end
end
