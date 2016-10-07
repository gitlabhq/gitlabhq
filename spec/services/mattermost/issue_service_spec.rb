require 'spec_helper'

describe Mattermost::IssueService, services: true do
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
    subject { service.execute }

    context 'Looking up on iid' do
      let(:params) { { text: 1 } }

      context 'when the user can not read issues' do
        it_behaves_like 'a 404 response'
      end

      context 'when the user has access' do
        context 'when the resource exists' do
          let(:issue) { create(:issue, project: project) }
          let(:params) { { text: issue.iid } }

          before do
            project.team << [user, :master]
          end

          it 'returns the resource' do
            expect(subject[:response_type]).to be :in_channel
            expect(subject[:text]).to start_with "### [#{issue.to_reference} "
          end
        end

        context 'when the resource does not exists' do
          it_behaves_like 'a 404 response'
        end
      end
    end

    context 'searching for issues' do
      let!(:issue) { create(:issue, project: project, title: 'Bird is the word') }
      let!(:issue1) { create(:issue, project: project, title: 'Everybody heard about the bird') }
      let(:params) { { text: 'search bird' } }

      context 'when the user has no access' do
        it_behaves_like 'a 404 response'
      end

      context 'when the user has acces' do
        before do
          project.team << [user, :master]
        end

        context 'when there are results' do
          it 'returns the resource' do
            expect(subject[:response_type]).to be :ephemeral
            expect(subject[:text]).to start_with "### Search results for"
          end
        end

        context 'when there is only one result' do
          let(:params) { { text: 'search about the bird' } }

          it 'returns the resource' do
            expect(subject[:response_type]).to be :in_channel
            expect(subject[:text]).to start_with "### [#{issue1.to_reference} "
          end
        end
      end
    end

    context 'creating an issue' do
      let(:params) { { text: "create The Trashmen\nBird is the word" } }

      context 'when the user has no access' do
        it_behaves_like 'a 404 response'
      end

      context 'when the user has acces' do
        before do
          project.team << [user, :master]
        end

        context 'it creates an issue' do
          it 'returns the resource' do
            expect(subject[:response_type]).to be :in_channel
            expect(subject[:text]).to match /The Trashmen/
          end
        end
      end
    end
  end
end
