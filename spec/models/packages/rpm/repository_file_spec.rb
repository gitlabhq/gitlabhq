# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryFile, type: :model do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:repository_file) { create(:rpm_repository_file) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
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
    let_it_be(:pending_destruction_repository_package_file) do
      create(:rpm_repository_file, :pending_destruction)
    end

    describe '.with_status' do
      subject { described_class.with_status(:pending_destruction) }

      it { is_expected.to contain_exactly(pending_destruction_repository_package_file) }
    end
  end
end
