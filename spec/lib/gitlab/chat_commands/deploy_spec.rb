require 'spec_helper'

describe Gitlab::ChatCommands::Deploy, service: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:user) { create(:user) }
    let(:regex_match) { described_class.match('deploy staging to production') }

    before do
      project.team << [user, :master]
    end

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'if no environment is defined' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'with environment' do
      let!(:staging) { create(:environment, name: 'staging', project: project) }
      let!(:build) { create(:ci_build, project: project) }
      let!(:deployment) { create(:deployment, environment: staging, deployable: build) }

      context 'without actions' do
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'with action' do
        let!(:manual1) do
          create(:ci_build, :manual, project: project, pipeline: build.pipeline, name: 'first', environment: 'production')
        end

        it 'returns success result' do
          expect(subject.type).to eq(:success)
          expect(subject.message).to include('Deployment from staging to production started')
        end

        context 'when duplicate action exists' do
          let!(:manual2) do
            create(:ci_build, :manual, project: project, pipeline: build.pipeline, name: 'second', environment: 'production')
          end

          it 'returns error' do
            expect(subject.type).to eq(:error)
            expect(subject.message).to include('Too many actions defined')
          end
        end

        context 'when teardown action exists' do
          let!(:teardown) do
            create(:ci_build, :manual, :teardown_environment,
                   project: project, pipeline: build.pipeline,
                   name: 'teardown', environment: 'production')
          end

          it 'returns success result' do
            expect(subject.type).to eq(:success)
            expect(subject.message).to include('Deployment from staging to production started')
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
