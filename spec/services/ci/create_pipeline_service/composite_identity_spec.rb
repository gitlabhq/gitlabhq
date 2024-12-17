# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :continuous_integration do # rubocop:disable RSpec/SpecFilePathFormat -- we breakdown Ci::CreatePipelineService E2E tests this way
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  subject(:pipeline) { service.execute(:push).payload }

  describe 'composite identity', :request_store do
    before do
      stub_ci_pipeline_yaml_file(config)
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

      context 'when user does not support composite identity' do
        it 'does not propagate the scoped user into each job' do
          expect(pipeline).to be_created_successfully
          expect(pipeline.builds).to be_present

          pipeline.builds.each do |job|
            expect(job.options).not_to have_key(:scoped_user_id)
          end
        end
      end
    end
  end
end
