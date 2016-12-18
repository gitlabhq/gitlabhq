require 'spec_helper'

describe UserUrlConstrainer, lib: true do
  let!(:user) { create(:user, username: 'dz') }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(user.username) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      let(:request) { build_request('foo') }

      it { expect(subject.matches?(request)).to be_falsey }
    end
  end

  def build_request(username)
    double(:request, params: { username: username })
  end
end
