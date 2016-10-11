require 'spec_helper'

describe UserUrlConstrainer, lib: true do
  let!(:username) { create(:user, username: 'dz') }

  describe '#find_resource' do
    it { expect(!!subject.find_resource('dz')).to be_truthy }
    it { expect(!!subject.find_resource('john')).to be_falsey }
  end
end
