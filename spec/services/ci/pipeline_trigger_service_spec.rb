require 'spec_helper'

describe Ci::PipelineTriggerService, services: true do
  let(:project) { create(:project, :repository) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    let(:user) { create(:user) }
    let(:trigger) { create(:ci_trigger, project: project, owner: user) }
    let(:result) { described_class.new(project, user, params).execute }

    let(:params) do
      { token: token, ref: ref, variables: variables }
    end

    before do
      project.add_developer(user)
    end

    context 'when params have an existsed trigger token' do
      let(:token) { trigger.token }

      context 'when params have an existsed ref' do
        let(:ref) { 'master' }
        let(:variables) {}

        it 'triggers a pipeline' do
          expect { result }.to change { Ci::Pipeline.count }.by(1)
          expect(result[:pipeline].ref).to eq(ref)
          expect(result[:pipeline].project).to eq(project)
          expect(result[:pipeline].user).to eq(trigger.owner)
          expect(result[:status]).to eq(:success)
        end

        context 'when params have a variable' do
          let(:variables) { { 'AAA' => 'AAA123' } }

          it 'has a variable' do
            expect { result }.to change { Ci::PipelineVariable.count }.by(1)
            expect(result[:pipeline].variables.first.key).to eq(variables.keys.first)
            expect(result[:pipeline].variables.first.value).to eq(variables.values.first)
          end
        end
      end

      context 'when params have a non-existsed ref' do
        let(:ref) { 'invalid-ref' }
        let(:variables) {}

        it 'does not trigger a pipeline' do
          expect { result }.not_to change { Ci::Pipeline.count }
          expect(result[:http_status]).to eq(400)
        end
      end
    end

    context 'when params have a non-existsed trigger token' do
      let(:token) { 'invalid-token' }
      let(:ref) {}
      let(:variables) {}

      it 'does not trigger a pipeline' do
        expect { result }.not_to change { Ci::Pipeline.count }
        expect(result).to be_nil
      end
    end
  end
end
