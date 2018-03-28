require 'spec_helper'

describe Gitlab::Ci::Status::Build::Created do
  subject do
    described_class.new(double('subject'))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }
  end
end
