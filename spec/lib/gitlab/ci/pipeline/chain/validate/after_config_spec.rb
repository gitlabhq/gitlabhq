# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user, :service_account, composite_identity_enforced: true) }
  let_it_be(:project) { create(:project, :repository, developers: user) }

  let(:pipeline) do
    build(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command
      .new(project: project, current_user: user, save_incompleted: true)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'when the `allow_composite_identities_to_run_pipelines` setting is disabled' do
      context 'when the user has a composite identity' do
        it 'breaks the pipeline chain with an error' do
          step.perform!

          expect(step.break?).to be_truthy
          expect(pipeline.errors.full_messages.first).to eq(
            'This pipeline did not run because the code should be reviewed by a non-AI user first. ' \
              'Please verify this change is okay before running a new pipeline.'
          )
          expect(pipeline.failure_reason).to eq('composite_identity_forbidden')
          expect(pipeline).to be_persisted
        end
      end

      context 'when the user does not have a composite identity' do
        let_it_be(:user) { create(:user) }

        it 'succeeds the step' do
          step.perform!

          expect(step.break?).to be_falsey
          expect(pipeline.errors).to be_empty
        end
      end

      context 'when the `allow_composite_identities_to_run_pipelines` setting is enabled' do
        before do
          project.update!(allow_composite_identities_to_run_pipelines: true)
        end

        context 'when the user has a composite identity' do
          it 'succeeds the step' do
            step.perform!

            expect(step.break?).to be_falsey
            expect(pipeline.errors).to be_empty
          end
        end

        context 'when the user does not have a composite identity' do
          let_it_be(:user) { create(:user) }

          it 'succeeds the step' do
            step.perform!

            expect(step.break?).to be_falsey
            expect(pipeline.errors).to be_empty
          end
        end
      end
    end
  end
end
