# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleVariable do
  subject { build(:ci_pipeline_schedule_variable) }

  it_behaves_like "CI variable"
end
