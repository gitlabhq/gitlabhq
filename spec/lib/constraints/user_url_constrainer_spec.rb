require 'spec_helper'

describe UserUrlConstrainer, lib: true do
  let!(:username) { create(:user, username: 'dz') }

  describe '#matches?' do
    it { expect(subject.matches?(request '/dz')).to be_truthy }
    it { expect(subject.matches?(request '/dz.atom')).to be_truthy }
    it { expect(subject.matches?(request '/dz/projects')).to be_falsey }
    it { expect(subject.matches?(request '/gitlab')).to be_falsey }
  end

  def request(path)
    OpenStruct.new(path: path)
  end
end
