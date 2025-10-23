# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::Mirror::BranchSkipFilter, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, :mirror) }

  let(:filter) { described_class.new(project) }

  describe '#skip_branch?' do
    subject { filter.skip_branch?(branch_name) }

    context 'when only_mirror_protected_branches is false and no regex' do
      let(:branch_name) { 'feature' }

      it { is_expected.to be_falsey }
    end

    context 'when only_mirror_protected_branches is true' do
      before do
        project.update!(only_mirror_protected_branches: true)
      end

      context 'with protected branch' do
        let(:branch_name) { 'main' }

        before do
          create(:protected_branch, project: project, name: branch_name)
        end

        it { is_expected.to be_falsey }
      end

      context 'with unprotected branch' do
        let(:branch_name) { 'feature' }

        it { is_expected.to be_truthy }
      end
    end

    context 'when mirror_branch_regex is set' do
      before do
        # Reset only_mirror_protected_branches to avoid validation conflict
        project.update!(only_mirror_protected_branches: false)
      end

      let!(:project_setting) { create(:project_setting, project: project, mirror_branch_regex: 'release-.*') }

      context 'with matching branch' do
        let(:branch_name) { 'release-1.0' }

        it { is_expected.to be_falsey }
      end

      context 'with non-matching branch' do
        let(:branch_name) { 'feature' }

        it { is_expected.to be_truthy }
      end
    end
  end
end
