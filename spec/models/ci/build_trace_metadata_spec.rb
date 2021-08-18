# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceMetadata do
  it { is_expected.to belong_to(:build) }
  it { is_expected.to belong_to(:trace_artifact) }

  it { is_expected.to validate_presence_of(:build) }
end
