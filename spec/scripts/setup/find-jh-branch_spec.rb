# frozen_string_literal: true

require 'fast_spec_helper'

# NOTE: Under the context of fast_spec_helper, when we `require 'gitlab'`
# we do not load the Gitlab client, but our own Gitlab module.
# Keep this in mind and just stub anything which might touch it!
require_relative '../../../scripts/setup/find-jh-branch'

RSpec.describe FindJhBranch, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- We use dashes in scripts
  subject { described_class.new }

  describe '#run' do
    context 'when it is not a merge request' do
      before do
        expect(subject).to receive(:merge_request?).and_return(false)
      end

      it 'returns JH_DEFAULT_BRANCH' do
        expect(subject.run).to eq(described_class::JH_DEFAULT_BRANCH)
      end
    end

    context 'when it is a merge request' do
      let(:branch_name) { 'branch-name' }
      let(:jh_branch_name) { 'branch-name-jh' }
      let(:default_branch) { 'main' }
      let(:merge_request) { double(target_branch: target_branch) }
      let(:target_branch) { default_branch }

      before do
        expect(subject).to receive(:merge_request?).and_return(true)

        expect(subject)
          .to receive(:branch_exist?)
          .with(described_class::JH_PROJECT_PATH, jh_branch_name)
          .and_return(jh_branch_exist)

        allow(subject).to receive(:ref_name).and_return(branch_name)
        allow(subject).to receive(:default_branch).and_return(default_branch)
        allow(subject).to receive(:merge_request).and_return(merge_request)
      end

      context 'when there is a corresponding JH branch' do
        let(:jh_branch_exist) { true }

        it 'returns the corresponding JH branch name' do
          expect(subject.run).to eq(jh_branch_name)
        end
      end

      context 'when there is no corresponding JH branch' do
        let(:jh_branch_exist) { false }

        it 'returns the default JH branch' do
          expect(subject.run).to eq(described_class::JH_DEFAULT_BRANCH)
        end

        context 'when it is targeting a default branch' do
          let(:target_branch) { '14-6-stable-ee' }
          let(:jh_stable_branch_name) { '14-6-stable-jh' }

          before do
            expect(subject)
              .to receive(:branch_exist?)
              .with(described_class::JH_PROJECT_PATH, jh_stable_branch_name)
              .and_return(jh_stable_branch_exist)
          end

          context 'when there is a corresponding JH stable branch' do
            let(:jh_stable_branch_exist) { true }

            it 'returns the corresponding JH stable branch' do
              expect(subject.run).to eq(jh_stable_branch_name)
            end
          end

          context 'when there is no corresponding JH stable branch' do
            let(:jh_stable_branch_exist) { false }

            it "raises #{described_class::BranchNotFound}" do
              expect { subject.run }.to raise_error(described_class::BranchNotFound)
            end
          end
        end

        context 'when it is not targeting the default branch' do
          let(:target_branch) { default_branch.swapcase }

          it 'returns the default JH branch' do
            expect(subject.run).to eq(described_class::JH_DEFAULT_BRANCH)
          end
        end
      end
    end
  end
end
