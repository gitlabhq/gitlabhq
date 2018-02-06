require 'spec_helper'

describe Ci::BuildTraceSectionName, model: true do
  subject { build(:ci_build_trace_section_name) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:trace_sections)}

  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
end
