# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :security_policy_management do # rubocop:disable RSpec/SpecFilePathFormat -- path is correct
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be_with_reload(:compliance_project) { create(:project, :empty_repo, group: group) }
  let_it_be(:user) { create(:user, developer_of: [project, compliance_project]) }

  let(:ref_name) { 'refs/heads/master' }
  let(:opts) { {} }

  let(:service) { described_class.new(project, user, { ref: ref_name }) }

  subject(:execute) do
    service.execute(:push, **opts)
  end

  describe '#execute' do
    let(:config) do
      {
        production: { stage: 'deploy', script: 'cap prod' },
        rspec: { stage: 'test', script: 'rspec' },
        spinach: { stage: 'test', script: 'spinach' }
      }
    end

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
    end

    context 'without security policy' do
      it 'creates new build source records for each build' do
        pipeline = nil
        expect do
          pipeline = execute.payload
        end.to change { Ci::BuildSource.count }.by(3)

        pipeline.builds.each do |build|
          source = Ci::BuildSource.find_by(project_id: project.id, build_id: build.id)
          expect(source.source).to eq('push')
        end
      end
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(populate_and_use_build_source_table: false)
      end

      it 'does not create build source records' do
        expect do
          execute.payload
        end.to not_change { Ci::BuildSource.count }
      end
    end
  end
end
