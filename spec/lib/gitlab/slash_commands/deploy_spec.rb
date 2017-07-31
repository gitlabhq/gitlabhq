require 'spec_helper'

describe Gitlab::SlashCommands::Deploy do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:user) { create(:user) }
    let(:regex_match) { described_class.match('deploy staging to production') }

    before do
      # Make it possible to trigger protected manual actions for developers.
      #
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: 'master', project: project)
    end

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'if no environment is defined' do
      it 'does not execute an action' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to eq("No action found to be executed")
      end
    end

    context 'with environment' do
      let!(:staging) { create(:environment, name: 'staging', project: project) }
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline) }
      let!(:deployment) { create(:deployment, environment: staging, deployable: build) }

      context 'without actions' do
        it 'does not execute an action' do
          expect(subject[:response_type]).to be(:ephemeral)
          expect(subject[:text]).to eq("No action found to be executed")
        end
      end

      context 'with action' do
        let!(:manual1) do
          create(:ci_build, :manual, pipeline: pipeline,
                                     name: 'first',
                                     environment: 'production')
        end

        it 'returns success result' do
          expect(subject[:response_type]).to be(:in_channel)
          expect(subject[:text]).to start_with('Deployment started from staging to production')
        end

        context 'when duplicate action exists' do
          let!(:manual2) do
            create(:ci_build, :manual, pipeline: pipeline,
                                       name: 'second',
                                       environment: 'production')
          end

          it 'returns error' do
            expect(subject[:response_type]).to be(:ephemeral)
            expect(subject[:text]).to eq('Too many actions defined')
          end
        end

        context 'when teardown action exists' do
          let!(:teardown) do
            create(:ci_build, :manual, :teardown_environment,
                   pipeline: pipeline, name: 'teardown', environment: 'production')
          end

          it 'returns the success message' do
            expect(subject[:response_type]).to be(:in_channel)
            expect(subject[:text]).to start_with('Deployment started from staging to production')
          end
        end
      end
    end
  end

  describe 'self.match' do
    it 'matches the environment' do
      match = described_class.match('deploy staging to production')

      expect(match[:from]).to eq('staging')
      expect(match[:to]).to eq('production')
    end
  end
end
