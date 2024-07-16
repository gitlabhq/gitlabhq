# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::EnsureResourceGroups do
  let(:project)  { create(:project) }
  let(:user)     { create(:user) }
  let(:stage) { build(:ci_stage, project: project, statuses: [job]) }
  let(:pipeline) { build(:ci_pipeline, project: project, stages: [stage]) }
  let!(:environment) { create(:environment, name: 'production', project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject { step.perform! }

    before do
      job.pipeline = pipeline
    end

    context 'when a pipeline contains a job that requires a resource group' do
      let!(:job) do
        build(:ci_build, project: project, environment: 'production', options: { resource_group_key: '$CI_ENVIRONMENT_NAME' })
      end

      it 'ensures the resource group existence' do
        expect { subject }.to change { Ci::ResourceGroup.count }.by(1)

        expect(project.resource_groups.find_by_key('production')).to be_present
        expect(job.resource_group.key).to eq('production')
        expect(job.options[:resource_group_key]).to be_nil
      end

      context 'when a resource group has already been existed' do
        before do
          create(:ci_resource_group, project: project, key: 'production')
        end

        it 'ensures the resource group existence' do
          expect { subject }.not_to change { Ci::ResourceGroup.count }

          expect(project.resource_groups.find_by_key('production')).to be_present
          expect(job.resource_group.key).to eq('production')
          expect(job.options[:resource_group_key]).to be_nil
        end
      end

      context 'when a resource group key contains an invalid character' do
        let!(:job) do
          build(:ci_build, project: project, environment: '!!!', options: { resource_group_key: '$CI_ENVIRONMENT_NAME' })
        end

        it 'does not create any resource groups' do
          expect { subject }.not_to change { Ci::ResourceGroup.count }

          expect(job.resource_group).to be_nil
        end
      end

      context 'when a resource group key contains a variable to be substituted' do
        let!(:job) do
          build(:ci_build, project: project, options: { resource_group_key: resource_group_key },
            yaml_variables: [{ key: "VAR", value: "TE" }, { key: "NESTED_VAR", value: "${VAR}ST" }])
        end

        context "when there is a single layer of variables" do
          let(:resource_group_key) { '${VAR}_GROUP' }

          it 'always expands the single layer of variables' do
            expect { subject }.to change { Ci::ResourceGroup.count }.by(1)
            expect(project.resource_groups.find_by_key('TE_GROUP')).to be_present
            expect(job.options[:resource_group_key]).to be_nil
          end
        end

        context "when there are nested variables" do
          let(:resource_group_key) { '${NESTED_VAR}_GROUP' }

          it 'expands all of the nested variables before creating the group' do
            expect { subject }.to change { Ci::ResourceGroup.count }.by(1)
            expect(project.resource_groups.find_by_key('TEST_GROUP')).to be_present
            expect(job.options[:resource_group_key]).to be_nil
          end
        end
      end
    end

    context 'when a pipeline does not contain a job that requires a resource group' do
      let!(:job) { build(:ci_build, project: project) }

      it 'does not create any resource groups' do
        expect { subject }.not_to change { Ci::ResourceGroup.count }
      end
    end
  end
end
