# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryFile, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:repository_file) { create(:rpm_repository_file) }

  let_it_be(:pending_destruction_repository_package_file) do
    create(:rpm_repository_file, :pending_destruction)
  end

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '.has_oversized_filelists?' do
    let!(:filelists) { create(:rpm_repository_file, :filelists, size: 21.megabytes) }

    subject { described_class.has_oversized_filelists?(project_id: filelists.project_id) }

    context 'when has oversized filelists' do
      it { expect(subject).to be true }
    end

    context 'when filelists.xml is not oversized' do
      before do
        filelists.update!(size: 19.megabytes)
      end

      it { expect(subject).to be_falsey }
    end

    context 'when there is no filelists.xml' do
      before do
        filelists.destroy!
      end

      it { expect(subject).to be_falsey }
    end
  end

  context 'when updating project statistics' do
    context 'when the package file has an explicit size' do
      it_behaves_like 'UpdateProjectStatistics' do
        subject { build(:rpm_repository_file, size: 42) }
      end
    end

    context 'when the package file does not have a size' do
      it_behaves_like 'UpdateProjectStatistics' do
        subject { build(:rpm_repository_file, size: nil) }
      end
    end
  end

  context 'with status scopes' do
    describe '.with_status' do
      subject { described_class.with_status(:pending_destruction) }

      it { is_expected.to contain_exactly(pending_destruction_repository_package_file) }
    end
  end

  describe '.installable' do
    subject { described_class.installable }

    it 'does not include non-displayable rpm repository files', :aggregate_failures do
      is_expected.to include(repository_file)
      is_expected.not_to include(pending_destruction_repository_package_file)
    end
  end

  describe '.installable_statuses' do
    it_behaves_like 'installable statuses'
  end
end
