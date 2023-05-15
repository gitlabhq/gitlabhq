# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::DataRepairDetail, type: :model, feature_category: :container_registry do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project: project) }

  it { is_expected.to belong_to(:project).required }

  it_behaves_like 'having unique enum values'

  describe '.ongoing_since' do
    let_it_be(:repair_detail1) { create(:container_registry_data_repair_detail, :ongoing, updated_at: 1.day.ago) }
    let_it_be(:repair_detail2) { create(:container_registry_data_repair_detail, :ongoing, updated_at: 20.minutes.ago) }
    let_it_be(:repair_detail3) do
      create(:container_registry_data_repair_detail, :completed, updated_at: 20.minutes.ago)
    end

    let_it_be(:repair_detail4) do
      create(:container_registry_data_repair_detail, :completed, updated_at: 31.minutes.ago)
    end

    subject { described_class.ongoing_since(30.minutes.ago) }

    it { is_expected.to contain_exactly(repair_detail1) }
  end
end
