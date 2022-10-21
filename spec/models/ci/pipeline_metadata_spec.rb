# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineMetadata do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:pipeline) }

  describe 'validations' do
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(255) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:pipeline) }
  end
end
