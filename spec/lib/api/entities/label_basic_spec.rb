# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::LabelBasic, feature_category: :team_planning do
  describe '#as_json' do
    subject { described_class.new(label).as_json }

    describe '#archived' do
      let(:label) { build_stubbed(:label, archived: true) }

      it { is_expected.to include(:archived) }

      context 'when labels_archive feature is disabled' do
        before do
          stub_feature_flags(labels_archive: false)
        end

        context 'with group label' do
          let(:group) { build_stubbed(:group) }
          let(:label) { build_stubbed(:group_label, group: group, archived: true) }

          it { is_expected.not_to include(:archived) }
        end

        context 'with project label' do
          let(:group) { build_stubbed(:group) }
          let(:project) { build_stubbed(:project, group: group) }
          let(:label) { build_stubbed(:label, project: project, archived: true) }

          it { is_expected.not_to include(:archived) }
        end

        context 'with admin label' do
          let(:label) { build_stubbed(:admin_label, archived: true) }

          it { is_expected.not_to include(:archived) }
        end
      end
    end
  end
end
