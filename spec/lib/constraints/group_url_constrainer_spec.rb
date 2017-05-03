require 'spec_helper'

describe GroupUrlConstrainer, lib: true do
  let!(:group) { create(:group, path: 'gitlab') }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(group.path) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'valid request for nested group' do
      let!(:nested_group) { create(:group, path: 'nested', parent: group) }
      let!(:request) { build_request('gitlab/nested') }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'valid request for nested group with reserved top level name' do
      let!(:nested_group) { create(:group, path: 'api', parent: group) }
      let!(:request) { build_request('gitlab/api') }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      let(:request) { build_request('foo') }

      it { expect(subject.matches?(request)).to be_falsey }
    end
  end

  def build_request(path)
    double(:request, params: { id: path })
  end
end
