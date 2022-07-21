# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::IssueEvent do
  shared_examples 'an IssueEvent' do
    it 'returns an instance of IssueEvent' do
      expect(issue_event).to be_an_instance_of(described_class)
    end

    context 'the returned IssueEvent' do
      it 'includes the issue event id' do
        expect(issue_event.id).to eq(6501124486)
      end

      it 'includes the issue event "event"' do
        expect(issue_event.event).to eq('closed')
      end

      it 'includes the issue event commit_id' do
        expect(issue_event.commit_id).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
      end

      it 'includes the issue event source' do
        expect(issue_event.source).to eq({ type: 'issue', id: 123456 })
      end

      it 'includes the issue_db_id' do
        expect(issue_event.issue_db_id).to eq(100500)
      end

      context 'when actor data present' do
        it 'includes the actor details' do
          expect(issue_event.actor)
            .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

          expect(issue_event.actor.id).to eq(4)
          expect(issue_event.actor.login).to eq('alice')
        end
      end

      context 'when actor data is empty' do
        let(:with_actor) { false }

        it 'does not return such info' do
          expect(issue_event.actor).to eq nil
        end
      end

      context 'when label data is present' do
        it 'includes the label_title' do
          expect(issue_event.label_title).to eq('label title')
        end
      end

      context 'when label data is empty' do
        let(:with_label) { false }

        it 'does not return such info' do
          expect(issue_event.label_title).to eq nil
        end
      end

      context 'when rename field is present' do
        it 'includes the old_title and new_title fields' do
          expect(issue_event.old_title).to eq('old title')
          expect(issue_event.new_title).to eq('new title')
        end
      end

      context 'when rename field is empty' do
        let(:with_rename) { false }

        it 'does not return such info' do
          expect(issue_event.old_title).to eq nil
          expect(issue_event.new_title).to eq nil
        end
      end

      context 'when milestone data is present' do
        it 'includes the milestone_title' do
          expect(issue_event.milestone_title).to eq('milestone title')
        end
      end

      context 'when milestone data is empty' do
        let(:with_milestone) { false }

        it 'does not return such info' do
          expect(issue_event.milestone_title).to eq nil
        end
      end

      context 'when assignee and assigner data is present' do
        it 'includes assignee and assigner details' do
          expect(issue_event.assignee)
            .to be_an_instance_of(Gitlab::GithubImport::Representation::User)
          expect(issue_event.assignee.id).to eq(5)
          expect(issue_event.assignee.login).to eq('tom')

          expect(issue_event.assigner)
            .to be_an_instance_of(Gitlab::GithubImport::Representation::User)
          expect(issue_event.assigner.id).to eq(6)
          expect(issue_event.assigner.login).to eq('jerry')
        end
      end

      context 'when assignee and assigner data is empty' do
        let(:with_assignee) { false }

        it 'does not return such info' do
          expect(issue_event.assignee).to eq nil
          expect(issue_event.assigner).to eq nil
        end
      end

      it 'includes the created timestamp' do
        expect(issue_event.created_at).to eq('2022-04-26 18:30:53 UTC')
      end
    end

    describe '#github_identifiers' do
      it 'returns a hash with needed identifiers' do
        expect(issue_event.github_identifiers).to eq({ id: 6501124486 })
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      event_resource = Struct.new(
        :id, :node_id, :url, :actor, :event, :commit_id, :commit_url, :label, :rename, :milestone,
        :source, :assignee, :assigner, :issue_db_id, :created_at, :performed_via_github_app,
        keyword_init: true
      )
      user_resource = Struct.new(:id, :login, keyword_init: true)
      event_resource.new(
        id: 6501124486,
        node_id: 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
        url: 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
        actor: with_actor ? user_resource.new(id: 4, login: 'alice') : nil,
        event: 'closed',
        commit_id: '570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
        commit_url: 'https://api.github.com/repos/octocat/Hello-World/commits'\
          '/570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
        label: with_label ? { name: 'label title' } : nil,
        rename: with_rename ? { from: 'old title', to: 'new title' } : nil,
        milestone: with_milestone ? { title: 'milestone title' } : nil,
        source: { type: 'issue', id: 123456 },
        assignee: with_assignee ? user_resource.new(id: 5, login: 'tom') : nil,
        assigner: with_assignee ? user_resource.new(id: 6, login: 'jerry') : nil,
        issue_db_id: 100500,
        created_at: '2022-04-26 18:30:53 UTC',
        performed_via_github_app: nil
      )
    end

    let(:with_actor) { true }
    let(:with_label) { true }
    let(:with_rename) { true }
    let(:with_milestone) { true }
    let(:with_assignee) { true }

    it_behaves_like 'an IssueEvent' do
      let(:issue_event) { described_class.from_api_response(response) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'an IssueEvent' do
      let(:hash) do
        {
          'id' => 6501124486,
          'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
          'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
          'actor' => (with_actor ? { 'id' => 4, 'login' => 'alice' } : nil),
          'event' => 'closed',
          'commit_id' => '570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
          'commit_url' =>
            'https://api.github.com/repos/octocat/Hello-World/commits/570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
          'label_title' => (with_label ? 'label title' : nil),
          'old_title' => with_rename ? 'old title' : nil,
          'new_title' => with_rename ? 'new title' : nil,
          'milestone_title' => (with_milestone ? 'milestone title' : nil),
          'source' => { 'type' => 'issue', 'id' => 123456 },
          'assignee' => (with_assignee ? { 'id' => 5, 'login' => 'tom' } : nil),
          'assigner' => (with_assignee ? { 'id' => 6, 'login' => 'jerry' } : nil),
          "issue_db_id" => 100500,
          'created_at' => '2022-04-26 18:30:53 UTC',
          'performed_via_github_app' => nil
        }
      end

      let(:with_actor) { true }
      let(:with_label) { true }
      let(:with_rename) { true }
      let(:with_milestone) { true }
      let(:with_assignee) { true }

      let(:issue_event) { described_class.from_json_hash(hash) }
    end
  end
end
