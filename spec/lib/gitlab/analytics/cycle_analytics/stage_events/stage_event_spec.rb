# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CycleAnalytics::StageEvents::StageEvent do
  it { expect(described_class).to respond_to(:name) }
  it { expect(described_class).to respond_to(:identifier) }

  it { expect(described_class.new({})).to respond_to(:object_type) }
end
