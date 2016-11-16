require 'spec_helper'

describe Gitlab::ChatCommands::Command, service: true do
  let(:project)         { create(:project) }
  let(:user)            { create(:user) }
  let(:params)          { { text: 'issue show 1' } }

  subject { described_class.new(project, user, params).execute }

  xdescribe '#execute' do
    context 'when issue show is triggered' do
      it 'calls IssueShowService' do
        expect_any_instance_of(Mattermost::Commands::IssueShowService).to receive(:new).with(project, user, params)

        subject
      end
    end
  end
end
