require 'spec_helper'

describe Gitlab::Ci::Error::MissingDependencies do
  it { expect(described_class).to be < StandardError }
end
