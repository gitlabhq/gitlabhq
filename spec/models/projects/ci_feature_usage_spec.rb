# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CiFeatureUsage, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:feature) }
  end

  describe '.insert_usage' do
    let_it_be(:project) { create(:project) }

    context 'when data is not a duplicate' do
      it 'creates a new record' do
        expect { described_class.insert_usage(project_id: project.id, default_branch: false, feature: :code_coverage) }
          .to change { described_class.count }

        expect(described_class.first).to have_attributes(
          project_id: project.id,
          default_branch: false,
          feature: 'code_coverage'
        )
      end
    end

    context 'when data is a duplicate' do
      before do
        create(:project_ci_feature_usage, project: project, default_branch: false, feature: :code_coverage)
      end

      it 'does not create a new record' do
        expect { described_class.insert_usage(project_id: project.id, default_branch: false, feature: :code_coverage) }
          .not_to change { described_class.count }
      end
    end
  end
end
