require 'spec_helper'

describe Gitlab::ChatCommands::IssueCreate, service: true do
  describe '#execute' do
    let(:project)  { create(:empty_project) }
    let(:user)     { create(:user) }
    let(:regex_match) { described_class.match("issue create bird is the word") }

    before { project.team << [user, :master] }

    subject { described_class.new(project, user).execute(regex_match) }

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
      let(:regex_match) { described_class.match("issue create bird is the word\n#{description}") }

      before { subject }

      it 'creates the issue with description' do
        expect(Issue.last.description).to eq description
      end
    end
  end
end
