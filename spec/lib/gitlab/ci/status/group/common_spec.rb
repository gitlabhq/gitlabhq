require 'spec_helper'

describe Gitlab::Ci::Status::Group::Common do
  subject do
    Class.new(Gitlab::Ci::Status::Group::Core)
      .new(nil, nil).extend(described_class)
  end

  it 'does not have action' do
    expect(subject).not_to have_action
  end

  it 'has details' do
    expect(subject).not_to have_details
  end
end
