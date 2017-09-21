require 'spec_helper'

describe Ci::PipelineTriggerService do
  let(:project) { create(:project, :repository) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    let(:user) { create(:user) }
    let(:trigger) { create(:ci_trigger, project: project, owner: user) }
    let(:result) { described_class.new(project, user, params).execute }

    before do
      project.add_developer(user)
    end

    context 'when trigger belongs to a different project' do
      let(:params) { { token: trigger.token, ref: 'master', variables: nil } }
      let(:trigger) { create(:ci_trigger, project: create(:project), owner: user) }

      it 'does nothing' do
        expect { result }.not_to change { Ci::Pipeline.count }
      end
    end

    context 'when params have an existsed trigger token' do
      context 'when params have an existsed ref' do
        let(:params) { { token: trigger.token, ref: 'master', variables: nil } }

        it 'triggers a pipeline' do
          expect { result }.to change { Ci::Pipeline.count }.by(1)
          expect(result[:pipeline].ref).to eq('master')
          expect(result[:pipeline].project).to eq(project)
          expect(result[:pipeline].user).to eq(trigger.owner)
          expect(result[:pipeline].trigger_requests.to_a)
            .to eq(result[:pipeline].builds.map(&:trigger_request).uniq)
          expect(result[:status]).to eq(:success)
        end

        context 'when commit message has [ci skip]' do
          before do
            allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { '[ci skip]' }
          end

          it 'ignores [ci skip] and create as general' do
            expect { result }.to change { Ci::Pipeline.count }.by(1)
            expect(result[:status]).to eq(:success)
          end
        end

        context 'when params have a variable' do
          let(:params) { { token: trigger.token, ref: 'master', variables: variables } }
          let(:variables) { { 'AAA' => 'AAA123' } }

          it 'has a variable' do
            expect { result }.to change { Ci::PipelineVariable.count }.by(1)
                             .and change { Ci::TriggerRequest.count }.by(1)
            expect(result[:pipeline].variables.map { |v| { v.key => v.value } }.first).to eq(variables)
            expect(result[:pipeline].trigger_requests.last.variables).to be_nil
          end
        end
      end

      context 'when params have a non-existsed ref' do
        let(:params) { { token: trigger.token, ref: 'invalid-ref', variables: nil } }

        it 'does not trigger a pipeline' do
          expect { result }.not_to change { Ci::Pipeline.count }
          expect(result[:http_status]).to eq(400)
        end
      end
    end

    context 'when params have a non-existsed trigger token' do
      let(:params) { { token: 'invalid-token', ref: nil, variables: nil } }

      it 'does not trigger a pipeline' do
        expect { result }.not_to change { Ci::Pipeline.count }
        expect(result).to be_nil
      end
    end
  end
end
