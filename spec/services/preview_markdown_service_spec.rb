require 'spec_helper'

describe PreviewMarkdownService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_developer(user)
  end

  describe 'user references' do
    let(:params) { { text: "Take a look #{user.to_reference}" } }
    let(:service) { described_class.new(project, user, params) }

    it 'returns users referenced in text' do
      result = service.execute

      expect(result[:users]).to eq [user.username]
    end
  end

  context 'new note with quick actions' do
    let(:issue) { create(:issue, project: project) }
    let(:params) do
      {
        text: "Please do it\n/assign #{user.to_reference}",
        quick_actions_target_type: 'Issue',
        quick_actions_target_id: issue.id
      }
    end
    let(:service) { described_class.new(project, user, params) }

    it 'removes quick actions from text' do
      result = service.execute

      expect(result[:text]).to eq 'Please do it'
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq "Assigns #{user.to_reference}."
    end
  end

  context 'merge request description' do
    let(:params) do
      {
        text: "My work\n/estimate 2y",
        quick_actions_target_type: 'MergeRequest'
      }
    end
    let(:service) { described_class.new(project, user, params) }

    it 'removes quick actions from text' do
      result = service.execute

      expect(result[:text]).to eq 'My work'
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq 'Sets time estimate to 2y.'
    end
  end
end
