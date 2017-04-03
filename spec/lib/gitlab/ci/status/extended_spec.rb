require 'spec_helper'

describe Gitlab::Ci::Status::Extended do
  subject do
    Class.new.include(described_class)
  end

  it 'requires subclass to implement matcher' do
    expect { subject.matches?(double, double) }
      .to raise_error(NotImplementedError)
  end
end
