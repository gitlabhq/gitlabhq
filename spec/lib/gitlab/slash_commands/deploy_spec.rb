# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Deploy, feature_category: :environment_management do
  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match('deploy staging to production') }

    before do
      # Make it possible to trigger protected manual actions for developers.
      #
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
        name: 'master', project: project)
    end

    subject do
      described_class.new(project, chat_name).execute(regex_match)
    end

    context 'if no environment is defined' do
      it 'does not execute an action' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to eq "Couldn't find a deployment manual action."
      end
    end

    context 'with environment' do
      let!(:staging) { create(:environment, name: 'staging', project: project) }
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline, environment: 'production') }
      let!(:deployment) { create(:deployment, :success, environment: staging, deployable: build) }

      context 'without actions' do
        it 'does not execute an action' do
          expect(subject[:response_type]).to be(:ephemeral)
          expect(subject[:text]).to eq "Couldn't find a deployment manual action."
        end
      end

      context 'when single action has been matched' do
        before do
          create(:ci_build, :manual, pipeline: pipeline,
            name: 'first',
            environment: 'production')
        end

        it 'returns success result' do
          expect(subject[:response_type]).to be(:in_channel)
          expect(subject[:text])
            .to start_with('Deployment started from staging to production')
        end
      end

      context 'when more than one action has been matched' do
        context 'when there is no specific actions with a environment name' do
          before do
            create(:ci_build, :manual, pipeline: pipeline,
              name: 'first',
              environment: 'production')

            create(:ci_build, :manual, pipeline: pipeline,
              name: 'second',
              environment: 'production')
          end

          it 'returns error about too many actions defined' do
            expect(subject[:text]).to eq("Couldn't find a deployment manual action.")
            expect(subject[:response_type]).to be(:ephemeral)
          end
        end

        context 'when one of the actions is environement specific action' do
          before do
            create(:ci_build, :manual, pipeline: pipeline,
              name: 'first',
              environment: 'production')

            create(:ci_build, :manual, pipeline: pipeline,
              name: 'production',
              environment: 'production')
          end

          it 'deploys to production' do
            expect(subject[:text])
              .to start_with('Deployment started from staging to production')
            expect(subject[:response_type]).to be(:in_channel)
          end
        end

        context 'when one of the actions is a teardown action' do
          before do
            create(:ci_build, :manual, pipeline: pipeline,
              name: 'first',
              environment: 'production')

            create(:ci_build, :manual, :teardown_environment,
              pipeline: pipeline, name: 'teardown', environment: 'production')
          end

          it 'deploys to production' do
            expect(subject[:text])
              .to start_with('Deployment started from staging to production')
            expect(subject[:response_type]).to be(:in_channel)
          end
        end
      end

      context 'with extra spaces in the deploy command' do
        let(:regex_match) { described_class.match('deploy    staging     to    production    ') }

        before do
          create(:ci_build, :manual, pipeline: pipeline, name: 'production', environment: 'production')
          create(:ci_build, :manual, pipeline: pipeline, name: 'not prod', environment: 'not prod')
        end

        it 'deploys to production' do
          expect(subject[:text])
            .to start_with('Deployment started from staging to production')
          expect(subject[:response_type]).to be(:in_channel)
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

    it 'matches the environment with spaces in it' do
      match = described_class.match('deploy staging env to production env')

      expect(match[:from]).to eq('staging env')
      expect(match[:to]).to eq('production env')
    end

    it 'matches the environment name with surrounding spaces' do
      match = described_class.match('deploy    staging    to    production    ')

      # The extra spaces are stripped later in the code
      expect(match[:from]).to eq('staging')
      expect(match[:to]).to eq('production')
    end

    it 'returns nil for text that is not a deploy command' do
      match = described_class.match('foo bar')

      expect(match).to be_nil
    end

    it 'returns nil for a partial command' do
      match = described_class.match('deploy staging to   ')

      expect(match).to be_nil
    end

    context 'with ReDoS attempts' do
      def duration_for(&block)
        start = Time.zone.now
        yield if block
        Time.zone.now - start
      end

      it 'has smaller than linear execution time growth with a malformed "to"', :aggregate_failures,
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/469617' do
        expect do
          Timeout.timeout(3.seconds) do
            sample1 = duration_for { described_class.match("deploy abc t" + ("o" * 100000) + "X") }
            sample2 = duration_for { described_class.match("deploy abc t" + ("o" * 400000) + "X") }

            # Expectation uses 2x as linear function to allow for runtime variations and avoid flakyness
            expect(sample2 / sample1).to be < 8
          end
        end.not_to raise_error
      end
    end
  end
end
