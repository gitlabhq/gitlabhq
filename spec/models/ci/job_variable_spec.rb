# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobVariable do
  subject { build(:ci_job_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to belong_to(:job) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:job_id) }
end
