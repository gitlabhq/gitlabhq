require 'spec_helper'

describe NamespaceUrlConstrainer, lib: true do
  let!(:group) { create(:group, path: 'gitlab') }
  subject { NamespaceUrlConstrainer.new }

  describe '#matches?' do
    context 'existing namespace' do
      it { expect(subject.matches?(request '/gitlab')).to be_truthy }
      it { expect(subject.matches?(request '/gitlab.atom')).to be_truthy }
      it { expect(subject.matches?(request '/gitlab/')).to be_truthy }
      it { expect(subject.matches?(request '//gitlab/')).to be_truthy }
    end

    context 'non-existing namespace' do
      it { expect(subject.matches?(request '/gitlab-ce')).to be_falsey }
      it { expect(subject.matches?(request '/gitlab.ce')).to be_falsey }
      it { expect(subject.matches?(request '/g/gitlab')).to be_falsey }
      it { expect(subject.matches?(request '/.gitlab')).to be_falsey }
    end
  end

  def request(path)
    OpenStruct.new(path: path)
  end
end
