require 'spec_helper'

describe Ci::PipelineScheduleVariable, models: true do
  subject { build(:ci_pipeline_schedule_variable) }

  it { is_expected.to include_module(HasVariable) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:pipeline_schedule_id) }
end
