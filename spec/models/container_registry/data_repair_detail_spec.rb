# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::DataRepairDetail, type: :model, feature_category: :container_registry do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project: project) }

  it { is_expected.to belong_to(:project).required }
end
