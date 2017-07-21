require 'spec_helper'

describe Ci::PipelineTriggerService, services: true do
  let(:project) { create(:project, :repository) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    let(:user) { create(:user) }

    before do
      project.add_developer(user)
    end

    let(:result) { described_class.new(project, user, params).execute }
    let(:trigger) { create(:ci_trigger, project: project, owner: user) }

    context 'when params have an existsed trigger token' do
      let(:token) { trigger.token }

      context 'when params have an existsed ref' do
        let(:ref) { 'master' }

        it 'triggers a pipeline' do
          expect { result }.to change { Ci::Pipeline.count }.by(1)
          expect(result[:pipeline].ref).to eq(ref)
          expect(result[:pipeline].project).to eq(project)
          expect(result[:pipeline].user).to eq(trigger.owner)
          expect(result[:status]).to eq(:success)
        end

        context 'when params have a variable' do
          let(:variables) { [{ key: 'AAA', value: 'AAA123' }] }

          it 'has a variable' do
            expect { result }.to change { Ci::PipelineVariable.count }.by(1)
            expect(result[:pipeline].variables.first.key).to eq(variables.first[:key])
            expect(result[:pipeline].variables.first.value).to eq(variables.first[:value])
          end
        end

        context 'when params have two variables' do
          let(:variables) { [{ key: 'AAA', value:'AAA123' }, { key: 'BBB', value:'BBB123' }] }

          it 'has two variables' do
            expect { result }.to change { Ci::PipelineVariable.count }.by(2)
            expect(result[:pipeline].variables.first.key).to eq(variables.first[:key])
            expect(result[:pipeline].variables.first.value).to eq(variables.first[:value])
            expect(result[:pipeline].variables.last.key).to eq(variables.last[:key])
            expect(result[:pipeline].variables.last.value).to eq(variables.last[:value])
          end
        end

        context 'when params have two variables and keys are duplicated' do
          let(:variables) { [{ key: 'AAA', value:'AAA123' }, { key: 'AAA', value:'BBB123' }] }

          it 'returns error' do
            expect { result }.not_to change { Ci::Pipeline.count }
            expect(result[:http_status]).to eq(400)
          end
        end
      end

      context 'when params have a non-existsed ref' do
        let(:ref) { 'invalid-ref' }

        it 'does not trigger a pipeline' do
          expect { result }.not_to change { Ci::Pipeline.count }
          expect(result[:http_status]).to eq(400)
        end
      end
    end

    context 'when params have a non-existsed trigger token' do
      let(:token) { 'invalid-token' }

      it 'does not trigger a pipeline' do
        expect { result }.not_to change { Ci::Pipeline.count }
        expect(result).to be_nil
      end
    end
  end

  def params
    { token: defined?(token) ? token : nil,
      ref: defined?(ref) ? ref : nil,
      variables: defined?(variables) ? variables : nil }
  end
end
