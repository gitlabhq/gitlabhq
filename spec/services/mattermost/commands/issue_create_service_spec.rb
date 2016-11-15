require 'spec_helper'

describe Mattermost::Commands::IssueCreateService, service: true do
  describe '#execute' do
    let(:project)  { create(:empty_project) }
    let(:user)     { create(:user) }
    let(:params)   { { text: "issue create bird is the word" } }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user, params).execute }

    context 'without description' do
      it 'creates the issue' do
        expect do
          subject # this trigger the execution
        end.to change { project.issues.count }.by(1)

        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match 'bird is the word'
      end
    end

    context 'with description' do
      let(:description) { "Surfin bird" }
      let(:params) { { text: "issue create The bird is the word\n#{description}" } }

      before { subject }

      it 'creates the issue with description' do
        expect(Issue.last.description).to eq description
      end
    end
  end
end
