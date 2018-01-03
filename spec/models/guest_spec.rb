require 'spec_helper'

describe Guest do
  let(:public_project) { build_stubbed(:project, :public) }
  let(:private_project) { build_stubbed(:project, :private) }
  let(:internal_project) { build_stubbed(:project, :internal) }

  describe '.can_pull?' do
    context 'when project is private' do
      it 'does not allow to pull the repo' do
        expect(described_class.can?(:download_code, private_project)).to eq(false)
      end
    end

    context 'when project is internal' do
      it 'does not allow to pull the repo' do
        expect(described_class.can?(:download_code, internal_project)).to eq(false)
      end
    end

    context 'when project is public' do
      context 'when repository is disabled' do
        it 'does not allow to pull the repo' do
          public_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

          expect(described_class.can?(:download_code, public_project)).to eq(false)
        end
      end

      context 'when repository is accessible only by team members' do
        it 'does not allow to pull the repo' do
          public_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::PRIVATE)

          expect(described_class.can?(:download_code, public_project)).to eq(false)
        end
      end

      context 'when repository is enabled' do
        it 'allows to pull the repo' do
          expect(described_class.can?(:download_code, public_project)).to eq(true)
        end
      end
    end
  end
end
