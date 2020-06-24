# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentMergeRequest do
  let(:mr) { create(:merge_request, :merged) }
  let(:deployment) { create(:deployment, :success, project: project) }
  let(:project) { mr.project }

  subject { described_class.new(deployment: deployment, merge_request: mr) }

  it { is_expected.to belong_to(:deployment).required }
  it { is_expected.to belong_to(:merge_request).required }
end
