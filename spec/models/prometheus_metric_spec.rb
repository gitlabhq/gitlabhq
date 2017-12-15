require 'spec_helper'

describe PrometheusMetric, type: :model do
  subject { build(:prometheus_metric) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:query) }
end
