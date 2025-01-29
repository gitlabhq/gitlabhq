# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::BuildInfo, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:pipeline) }
  end

  context 'with some build infos' do
    let_it_be(:package) { create(:generic_package) }
    let_it_be(:build_infos) { create_list(:package_build_info, 3, :with_pipeline, package: package) }
    let_it_be(:build_info_with_no_pipeline) { create(:package_build_info) }

    describe '.pluck_pipeline_ids' do
      subject { package.build_infos.pluck_pipeline_ids.sort }

      it { is_expected.to eq(build_infos.map(&:pipeline_id).sort) }
    end

    describe '.without_empty_pipelines' do
      subject { package.build_infos.without_empty_pipelines }

      it { is_expected.to contain_exactly(*build_infos) }
    end

    describe '.order_by_pipeline_id asc' do
      subject { package.build_infos.order_by_pipeline_id(:asc) }

      it { is_expected.to eq(build_infos) }
    end

    describe '.order_by_pipeline_id desc' do
      subject { package.build_infos.order_by_pipeline_id(:desc) }

      it { is_expected.to eq(build_infos.reverse) }
    end

    describe '.with_pipeline_id_less_than' do
      subject { package.build_infos.with_pipeline_id_less_than(build_infos[1].pipeline_id) }

      it { is_expected.to contain_exactly(build_infos[0]) }
    end

    describe '.with_pipeline_id_greater_than' do
      subject { package.build_infos.with_pipeline_id_greater_than(build_infos[1].pipeline_id) }

      it { is_expected.to contain_exactly(build_infos[2]) }
    end
  end
end
