# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::PipelinesSinceSetupExist, feature_category: :observability do
  let_it_be(:group, freeze: true) { create(:group) }
  let_it_be(:project, freeze: true) { create(:project, group: group) }
  let_it_be(:o11y_setting, freeze: true) do
    create(:observability_group_o11y_setting, group: group, created_at: 2.days.ago)
  end

  subject(:result) { described_class.new(group).execute }

  context 'when group has no observability setting' do
    let_it_be(:group_without_setting) { create(:group) }

    it { expect(described_class.new(group_without_setting).execute).to be(false) }
  end

  context 'when group has no projects' do
    let_it_be(:empty_group) { create(:group) }
    let(:group) { empty_group }

    before do
      create(:observability_group_o11y_setting, group: empty_group, created_at: 2.days.ago)
    end

    it { is_expected.to be(false) }
  end

  context 'when group has projects but no matching pipelines' do
    it { is_expected.to be(false) }
  end

  context 'when matching pipelines exist' do
    before do
      create(:ci_pipeline, :success, project: project, finished_at: 1.day.ago)
    end

    it { is_expected.to be(true) }
  end

  context 'when pipeline started before setup but finished after' do
    before do
      create(:ci_pipeline, :success,
        project: project,
        created_at: 3.days.ago,
        finished_at: 1.day.ago
      )
    end

    it { is_expected.to be(false) }
  end

  context 'when pipeline finished before setup' do
    before do
      create(:ci_pipeline, :success, project: project, finished_at: 3.days.ago)
    end

    it { is_expected.to be(false) }
  end

  context 'when pipeline has canceled status' do
    before do
      create(:ci_pipeline, :canceled, project: project, finished_at: 1.day.ago)
    end

    it { is_expected.to be(false) }
  end

  context 'when pipeline source is not a CI source' do
    before do
      create(
        :ci_pipeline, :success,
        source: :ondemand_dast_scan,
        project: project,
        finished_at: 1.day.ago
      )
    end

    it { is_expected.to be(false) }
  end
end
