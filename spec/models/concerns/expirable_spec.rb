require 'spec_helper'

describe Expirable do
  describe 'ProjectMember' do
    let(:no_expire) { create(:project_member) }
    let(:expire_later) { create(:project_member, expires_at: Time.current + 6.days) }
    let(:expired) { create(:project_member, expires_at: Time.current - 6.days) }

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
