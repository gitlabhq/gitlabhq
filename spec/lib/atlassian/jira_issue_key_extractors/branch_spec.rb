# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraIssueKeyExtractors::Branch, feature_category: :integrations do
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:branch) { project.repository.find_branch('improve/awesome') }

  describe '.has_keys?' do
    it 'delegates to `#issue_keys?`' do
      expect_next(described_class) do |instance|
        expect(instance).to receive_message_chain(:issue_keys, :any?)
      end

      described_class.has_keys?(project, branch.name)
    end
  end

  describe '#issue_keys' do
    subject { described_class.new(project, branch.name).issue_keys }

    context 'when branch name does not refer to an issue' do
      it { is_expected.to eq([]) }
    end

    context 'when branch name refers to an issue' do
      before do
        allow(branch).to receive(:name).and_return('BRANCH-1')
      end

      it { is_expected.to eq(['BRANCH-1']) }

      context 'when there is a related open merge request, and related closed merge request' do
        before_all do
          create(:merge_request,
            source_project: project,
            source_branch: 'BRANCH-1',
            title: 'OPEN_MR_TITLE-1',
            description: 'OPEN_MR_DESC-1'
          )

          create(:merge_request, :closed,
            source_project: project,
            source_branch: 'BRANCH-1',
            title: 'CLOSED_MR_TITLE-2',
            description: 'CLOSED_MR_DESC-2'
          )
        end

        it { is_expected.to eq(%w[BRANCH-1 OPEN_MR_TITLE-1 OPEN_MR_DESC-1]) }
      end
    end
  end
end
