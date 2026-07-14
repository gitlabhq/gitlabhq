# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageFileable, type: :model, feature_category: :package_registry do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:instance, freeze: false) { build(:conan_recipe_revision) }

  describe 'associations' do
    subject { instance }

    it 'has many file_metadata' do
      is_expected.to have_many(:file_metadata)
    end

    it 'has many package_files through file_metadata' do
      is_expected.to have_many(:package_files).through(:file_metadata)
    end
  end

  describe '#orphan?' do
    subject { instance.orphan? }

    context 'when package_files is empty' do
      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when package_files is not empty' do
      # `freeze: false` is required in this spec: one or more `let_it_be` subjects
      # cannot be frozen by default (deep_freeze traversal failure, a non-AR
      # subject, or an in-memory mutation that survives reload/refind). Do not
      # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
      # (see gitlab-org/gitlab#602925).
      let_it_be(:package_file, freeze: false) do
        create(:conan_package_file, :conan_recipe_file, package: instance.package, conan_recipe_revision: instance)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end
end
