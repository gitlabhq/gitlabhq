# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let(:service) { described_class.new(project, user, params) }
  let(:params) { {} }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
    end

    let(:config) do
      { rspec: { script: 'echo', only: ['merge_requests'] } }
    end

    let(:merge_request) do
      create(:merge_request,
        source_branch: 'feature',
        source_project: project,
        target_branch: 'master',
        target_project: project)
    end

    it 'creates a detached merge request pipeline' do
      expect { subject }.to change { Ci::Pipeline.count }.by(1)

      expect(subject).to be_persisted
      expect(subject).to be_detached_merge_request_pipeline
    end

    it 'defaults to merge_request_event' do
      expect(subject.source).to eq('merge_request_event')
    end

    context 'when service is called multiple times' do
      it 'creates a pipeline once' do
        expect do
          service.execute(merge_request)
          service.execute(merge_request)
        end.to change { Ci::Pipeline.count }.by(1)
      end

      context 'when allow_duplicate option is true' do
        let(:params) { { allow_duplicate: true } }

        it 'creates pipelines multiple times' do
          expect do
            service.execute(merge_request)
            service.execute(merge_request)
          end.to change { Ci::Pipeline.count }.by(2)
        end
      end
    end

    context 'when .gitlab-ci.yml does not use workflow:rules' do
      context 'without only: [merge_requests] keyword' do
        let(:config) do
          { rspec: { script: 'echo' } }
        end

        it 'does not create a pipeline' do
          expect { subject }.not_to change { Ci::Pipeline.count }
        end
      end

      context 'with rules that specify creation on a tag' do
        let(:config) do
          {
            rspec: {
              script: 'echo',
              rules: [{ if: '$CI_COMMIT_TAG' }]
            }
          }
        end

        it 'does not create a pipeline' do
          expect { subject }.not_to change { Ci::Pipeline.count }
        end
      end
    end

    context 'when workflow:rules are specified' do
      context 'when rules request creation on merge request' do
        let(:config) do
          {
            workflow: {
              rules: [{ if: '$CI_MERGE_REQUEST_ID' }]
            },
            rspec: { script: 'echo' }
          }
        end

        it 'creates a detached merge request pipeline' do
          expect { subject }.to change { Ci::Pipeline.count }.by(1)

          expect(subject).to be_persisted
          expect(subject).to be_detached_merge_request_pipeline
        end
      end

      context 'with rules do specify creation on a tag' do
        let(:config) do
          {
            workflow: {
              rules: [{ if: '$CI_COMMIT_TAG' }]
            },
            rspec: { script: 'echo' }
          }
        end

        it 'does not create a pipeline' do
          expect { subject }.not_to change { Ci::Pipeline.count }
        end
      end
    end
  end
end
