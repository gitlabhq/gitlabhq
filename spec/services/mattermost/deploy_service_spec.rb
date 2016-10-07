require 'spec_helper'

describe Mattermost::DeployService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  shared_examples 'a 404 response' do
    it 'responds with a 404 message' do
      expect(subject[:response_type]).to be :ephemeral
      expect(subject[:text]).to start_with '404 not found!'
    end
  end

  describe '#execute' do
    let(:params) { { text: 'envname to action' } }
    subject { service.execute }

    context 'when the environment can not be found' do
      it_behaves_like 'a 404 response'
    end

    context 'the environment exists' do
      let!(:deployment) { create(:deployment) }
      let(:project) { deployment.environment.project }

      context 'the user has no access' do
        it_behaves_like 'a 404 response'
      end

      context 'the user has access' do
        before do
          project.team << [user, :master]
        end

        let(:user) { create(:user) }
        let(:pipeline) { create(:pipeline) }
        let!(:build) { create(:build, :manual) }
        let(:params) { { text: "#{environment.name} to #{build.name}" } }

        it 'informs the user when it does not exist' do
          it_behaves_like 'a 404 response'
        end

        it 'executes the action if it exists' do
          allow(deployment).to receive(:manual_actions).and_return([build])

          expect(build).to receive(:manual_actions)
        end
      end
    end
  end
end
