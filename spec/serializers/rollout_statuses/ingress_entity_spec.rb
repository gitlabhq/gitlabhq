# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RolloutStatuses::IngressEntity do
  include KubernetesHelpers

  let(:canary_ingress) { kube_ingress(track: :canary) }

  let(:entity) do
    described_class.new(canary_ingress, request: double)
  end

  subject { entity.as_json }

  it 'exposes canary weight' do
    is_expected.to include(:canary_weight)
  end
end
