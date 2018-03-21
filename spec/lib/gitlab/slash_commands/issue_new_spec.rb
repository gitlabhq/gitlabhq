require 'spec_helper'

describe Gitlab::SlashCommands::IssueNew do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match("issue create bird is the word") }

    before do
      project.add_master(user)
    end

    subject do
      described_class.new(project, chat_name).execute(regex_match)
    end

    context 'without description' do
      it 'creates the issue' do
        expect { subject }.to change { project.issues.count }.by(1)

        expect(subject[:response_type]).to be(:in_channel)
      end
    end

    context 'with description' do
      let(:description) { "Surfin bird" }
      let(:regex_match) { described_class.match("issue create bird is the word\n#{description}") }

      it 'creates the issue with description' do
        subject

        expect(Issue.last.description).to eq(description)
      end
    end

    context "with more newlines between the title and the description" do
      let(:description) { "Surfin bird" }
      let(:regex_match) { described_class.match("issue create bird is the word\n\n#{description}\n") }

      it 'creates the issue' do
        expect { subject }.to change { project.issues.count }.by(1)
      end
    end

    context 'issue cannot be created' do
      let!(:issue)  { create(:issue, project: project, title: 'bird is the word') }
      let(:regex_match) { described_class.match("issue create #{'a' * 512}}") }

      it 'displays the errors' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match("- Title is too long")
      end
    end
  end

  describe '.match' do
    it 'matches the title without description' do
      match = described_class.match("issue create my title")

      expect(match[:title]).to eq('my title')
      expect(match[:description]).to eq("")
    end

    it 'matches the title with description' do
      match = described_class.match("issue create my title\n\ndescription")

      expect(match[:title]).to eq('my title')
      expect(match[:description]).to eq('description')
    end

    it 'matches the alias new' do
      match = described_class.match("issue new my title")

      expect(match).not_to be_nil
      expect(match[:title]).to eq('my title')
    end
  end
end
