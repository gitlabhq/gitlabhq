# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::WaitingForResource do
  it { expect(described_class).to be < Gitlab::Ci::Status::Processable::WaitingForResource }
end
