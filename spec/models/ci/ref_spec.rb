# frozen_string_literal: true

require 'spec_helper'

describe Ci::Ref do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:last_updated_by_pipeline) }

  it { is_expected.to validate_inclusion_of(:status).in_array(%w[success failed fixed]) }
  it { is_expected.to validate_presence_of(:last_updated_by_pipeline) }
end
