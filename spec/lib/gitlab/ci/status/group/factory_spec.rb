require 'spec_helper'

describe Gitlab::Ci::Status::Group::Factory do
  subject { described_class }

  it { is_expected.to respond_to(:common_helpers) }

  it 'inherrits from Status::Factory' do
    expect(subject).to be < Gitlab::Ci::Status::Factory
  end
end
