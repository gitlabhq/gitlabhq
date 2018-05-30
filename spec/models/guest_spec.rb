require 'spec_helper'

describe Guest do
  set(:public_project) { create(:project, :public) }
  set(:private_project) { create(:project, :private) }
  set(:internal_project) { create(:project, :internal) }

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
