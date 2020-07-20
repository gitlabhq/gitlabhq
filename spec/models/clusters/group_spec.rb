# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Group do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:group) }
end
