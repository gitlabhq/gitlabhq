require 'spec_helper'

describe Gitlab::Ci::Status::Build::Manual do
  subject do
    user = create(:user)
    build = create(:ci_build, :manual)
    described_class.new(Gitlab::Ci::Status::Core.new(build, user))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }
  end
end
