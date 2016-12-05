require 'spec_helper'

describe Gitlab::ChatCommands::Presenters::ShowIssue do
  let(:project) { create(:empty_project) }

  subject { described_class.new(issue).present }

  describe '#present' do
    context 'no issue to show' do
      let(:issue) { nil }

      it 'displays a 404 message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with("404 not found")
      end
    end

    context 'the issue is found' do
      let(:issue) { create(:issue, project: project) }
      let(:attachment) { subject[:attachments].first }
      let(:fields) { attachment[:fields] }

      it 'shows the issue to the channel' do
        expect(subject[:response_type]).to be(:in_channel)
        expect(subject[:status]).to be(200)

        expect(attachment[:author_icon]).to be_url
        expect(attachment[:title]).to eq(issue.title)
        expect(attachment[:title_link]).to be_url
      end

      it 'includes only one attachment' do
        expect(subject[:attachments].count).to be(1)
      end

      context 'when upvotes and notes where left' do
        before do
          create(:award_emoji, :upvote, awardable: issue)
          create(:note, noteable: issue, project: project)
        end

        it 'shows their number in the text' do
          expect(attachment[:text]).to eq(":+1: 1 :speech_balloon: 1")
        end
      end

      context 'is shows extra context in fields' do
        before do
          issue.update(assignee: issue.author)
        end

        it 'includes 3 fields' do
          expect(fields).to be_an(Array)
          expect(fields.count).to be(3)
        end

        it 'shows properties that are present' do
          assignee_field = fields.find { |item| item[:title] == "Assignee" }

          expect(assignee_field[:value]).to eq(issue.assignee.name)
        end

        it 'shows None for fields not present' do
          milestone_field = fields.find { |item| item[:title] == "Milestone" }

          expect(milestone_field[:value]).to eq("_None_")
        end
      end
    end
  end
end
