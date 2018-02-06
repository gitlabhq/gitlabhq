require 'spec_helper'

describe Ci::PipelineVariable do
  subject { build(:ci_pipeline_variable) }

  it { is_expected.to include_module(HasVariable) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:pipeline_id) }
end
