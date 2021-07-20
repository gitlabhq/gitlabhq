# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }

  let(:service) { described_class.new(project, user, ref: 'master') }
  let(:user) { developer }

  before_all do
    project.add_developer(developer)
  end

  describe '#execute' do
    subject { service.execute(:push).payload }

    context 'with deployment tier' do
      before do
        config = YAML.dump(
          deploy: {
            script: 'ls',
            environment: { name: "review/$CI_COMMIT_REF_NAME", deployment_tier: tier }
          })

        stub_ci_pipeline_yaml_file(config)
      end

      let(:tier) { 'development' }

      it 'creates the environment with the expected tier' do
        is_expected.to be_created_successfully

        expect(Environment.find_by_name("review/master")).to be_development
      end

      context 'when tier is testing' do
        let(:tier) { 'testing' }

        it 'creates the environment with the expected tier' do
          is_expected.to be_created_successfully

          expect(Environment.find_by_name("review/master")).to be_testing
        end
      end
    end
  end
end
