require 'spec_helper'

describe GroupUrlConstrainer, lib: true do
  let!(:username) { create(:group, path: 'gitlab-org') }

  describe '#find_resource' do
    it { expect(!!subject.find_resource('gitlab-org')).to be_truthy }
    it { expect(!!subject.find_resource('gitlab-com')).to be_falsey }
  end
end
