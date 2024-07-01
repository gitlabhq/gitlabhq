# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::IssueImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:bitbucket_user) { create(:user) }
  let_it_be(:identity) { create(:identity, user: bitbucket_user, extern_uid: '{123}', provider: :bitbucket) }
  let_it_be(:default_work_item_type) { create(:work_item_type) }
  let_it_be(:label) { create(:label, project: project) }
  let(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket', project) }

  let(:hash) do
    {
      iid: 111,
      title: 'title',
      description: 'description',
      state: 'closed',
      author: '{123}',
      author_nickname: 'bitbucket_user',
      milestone: 'my milestone',
      issue_type_id: default_work_item_type.id,
      label_id: label.id,
      created_at: Date.today,
      updated_at: Date.today
    }
  end

  subject(:importer) { described_class.new(project, hash) }

  before do
    allow(Gitlab::Git).to receive(:ref_name).and_return('refname')
    allow(Gitlab::Import::MentionsConverter).to receive(:new).and_return(mentions_converter)
  end

  describe '#execute' do
    it 'creates an issue' do
      expect { importer.execute }.to change { project.issues.count }.from(0).to(1)

      issue = project.issues.first

      expect(issue.description).to eq('description')
      expect(issue.author).to eq(bitbucket_user)
      expect(issue.closed?).to be_truthy
      expect(issue.milestone).to eq(project.milestones.first)
      expect(issue.work_item_type).to eq(default_work_item_type)
      expect(issue.labels).to eq([label])
      expect(issue.created_at).to eq(Date.today)
      expect(issue.updated_at).to eq(Date.today)
      expect(issue.imported_from).to eq('bitbucket')
    end

    it 'converts mentions in the description' do
      expect(mentions_converter).to receive(:convert).once.and_call_original

      importer.execute
    end

    context 'when the author does not have a bitbucket identity' do
      before do
        identity.update!(provider: :github)
      end

      it 'sets the author to the project creator and adds the author to the description' do
        importer.execute

        issue = project.issues.first

        expect(issue.author).to eq(project.creator)
        expect(issue.description).to eq("*Created by: bitbucket_user*\n\ndescription")
      end
    end

    context 'when a milestone with the same title exists' do
      let_it_be(:milestone) { create(:milestone, project: project, title: 'my milestone') }

      it 'assigns the milestone and does not create a new milestone' do
        expect { importer.execute }.not_to change { project.milestones.count }

        expect(project.issues.first.milestone).to eq(milestone)
      end
    end

    context 'when a milestone with the same title does not exist' do
      it 'creates a new milestone and assigns it' do
        expect { importer.execute }.to change { project.milestones.count }.from(0).to(1)

        expect(project.issues.first.milestone).to eq(project.milestones.first)
      end
    end

    context 'when an error is raised' do
      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        described_class.new(project, hash.except(:title)).execute
      end
    end

    it 'logs its progress' do
      allow(Gitlab::Import::MergeRequestCreator).to receive_message_chain(:new, :execute)

      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(include(message: 'starting', iid: anything)).and_call_original
      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(include(message: 'finished', iid: anything)).and_call_original

      importer.execute
    end

    it 'increments the issue counter' do
      expect_next_instance_of(Gitlab::Import::Metrics) do |metrics|
        expect(metrics).to receive_message_chain(:issues_counter, :increment)
      end

      importer.execute
    end
  end
end
