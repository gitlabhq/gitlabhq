require 'spec_helper'

describe Gitlab::Ci::Status::Extended::Base do
  subject do
    Class.new.extend(described_class)
  end

  it 'requires subclass to implement matcher' do
    expect { subject.matches?(double) }
      .to raise_error(NotImplementedError)
  end
end
