# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Queue::BuildQueueService, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build_1) { create(:ci_build, :created, pipeline: pipeline) }
  let_it_be(:pending_build_1) { create(:ci_pending_build, build: build_1, project: project) }

  describe 'build_candidates' do
    subject(:build_candidates) { described_class.new(runner).build_candidates }

    let!(:tagged_build) { create(:ci_build, :created, pipeline: pipeline, tag_list: runner_matching_tags) }
    let!(:protected_build) { create(:ci_build, :created, :protected, pipeline: pipeline) }
    let!(:pending_tagged_build) { create(:ci_pending_build, build: tagged_build, project: project) }
    let!(:pending_protected_build) { create(:ci_pending_build, build: protected_build, project: project) }

    where(:runner_traits, :runner_args) do
      [:instance] | {}
      [:group]    | { groups: [ref(:group)] }
      [:project]  | { projects: [ref(:project)] }
    end

    with_them do
      let(:runner_matching_tags) { %w[tag1 tag2] }
      let(:runner_without_tags) { create(:ci_runner, *runner_traits, **runner_args) }
      let(:runner_with_tags) { create(:ci_runner, :tagged_only, *runner_traits, **runner_args) }
      let(:protected_runner) { create(:ci_runner, :ref_protected, *runner_traits, **runner_args) }

      context 'when runner has tags' do
        let(:runner) { runner_with_tags }

        it 'returns tagged build candidates' do
          is_expected.to contain_exactly(pending_tagged_build)
        end
      end

      context 'when runner can pick untagged builds' do
        let(:runner) { runner_without_tags }

        it 'returns untagged build candidates' do
          is_expected.to contain_exactly(pending_build_1, pending_protected_build)
        end
      end

      context 'when protected runner has tags' do
        let(:runner) { protected_runner }

        it 'returns protected build candidates' do
          is_expected.to contain_exactly(pending_protected_build)
        end
      end
    end
  end
end
