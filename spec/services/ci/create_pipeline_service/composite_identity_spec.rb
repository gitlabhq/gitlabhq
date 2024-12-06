# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :continuous_integration do # rubocop:disable RSpec/SpecFilePathFormat -- we breakdown Ci::CreatePipelineService E2E tests this way
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:scoped_user) { create(:user) }

  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  subject(:pipeline) { service.execute(:push).payload }

  before_all do
    project.add_maintainer(scoped_user)
  end

  describe 'composite identity', :request_store do
    before do
      stub_ci_pipeline_yaml_file(config)

      allow(user).to receive(:has_composite_identity?).and_return(true)
      ::Gitlab::Auth::Identity.fabricate(user).link!(scoped_user)
    end

    context 'when job does not generate options' do
      let(:config) do
        <<~YAML
          build:
            script: echo
            timeout: 1h
          test:
            trigger: test-project
        YAML
      end

      it 'propagates the scoped user into each job without overriding `options`' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds).to be_present

        options = pipeline.statuses.map(&:options)
        expect(options).to eq [
          { script: ['echo'], job_timeout: 1.hour.to_i, scoped_user_id: scoped_user.id },
          { trigger: { project: 'test-project' }, scoped_user_id: scoped_user.id }
        ]
      end

      context 'when user does not support composite identity' do
        before do
          allow(user).to receive(:has_composite_identity?).and_return(false)
        end

        it 'does not propagate the scoped user into each job' do
          expect(pipeline).to be_created_successfully
          expect(pipeline.builds).to be_present

          pipeline.builds.each do |job|
            expect(job.options).not_to include(scoped_user_id: scoped_user.id)
          end
        end
      end
    end
  end
end
