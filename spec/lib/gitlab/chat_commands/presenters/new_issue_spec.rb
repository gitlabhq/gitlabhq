require 'spec_helper'

describe Gitlab::ChatCommands::Presenters::NewIssue do
  let(:project) { create(:empty_project) }

  subject { described_class.new(issue).present }

  describe '#present' do
    context 'an error occurred' do
      let(:current_user) { create(:admin) }
      let(:issue) do
        Issues::CreateService.new(project, current_user, title: '').execute
      end

      it 'displays the errors' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to eq("The action was not successful, because:\n- Title can't be blank")
      end
    end

    context 'the issue was created' do
      let(:issue) { create(:issue, project: project) }
      let(:attachment) { subject[:attachments].first }

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

      it 'converts the markdown title to slacks format' do
        expect(attachment[:pretext]).not_to match /New issue by [@#{issue.author.to_reference}]/
        expect(attachment[:pretext]).to match /New issue by <\S+\|#{issue.author.to_reference}>/
      end
    end
  end
end
