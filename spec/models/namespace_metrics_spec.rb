require 'spec_helper'

describe NamespaceMetrics, models: true do
  it { is_expected.to belong_to(:namespace) }

  it { is_expected.to validate_presence_of(:namespace) }
end
