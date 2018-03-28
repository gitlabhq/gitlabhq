require 'spec_helper'

describe Gitlab::Ci::Status::Build::Skipped do
  subject do
    described_class.new(double('subject'))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end
end
