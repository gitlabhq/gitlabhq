# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::Issue, feature_category: :importers do
  let_it_be(:work_item_type_id) { ::WorkItems::Type.default_issue_type.id }

  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  shared_examples 'an Issue' do
    it 'returns an instance of Issue' do
      expect(issue).to be_an_instance_of(described_class)
    end

    context 'the returned Issue' do
      it 'includes the issue number' do
        expect(issue.iid).to eq(42)
      end

      it 'includes the issue title' do
        expect(issue.title).to eq('My Issue')
      end

      it 'includes the issue description' do
        expect(issue.description).to eq('This is my issue')
      end

      it 'includes the milestone number' do
        expect(issue.milestone_number).to eq(4)
      end

      it 'includes the issue state' do
        expect(issue.state).to eq(:opened)
      end

      it 'includes the issue assignees' do
        expect(issue.assignees[0])
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(issue.assignees[0].id).to eq(4)
        expect(issue.assignees[0].login).to eq('alice')
      end

      it 'includes the label names' do
        expect(issue.label_names).to eq(%w[bug])
      end

      it 'includes the author details' do
        expect(issue.author)
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(issue.author.id).to eq(4)
        expect(issue.author.login).to eq('alice')
      end

      it 'includes the created timestamp' do
        expect(issue.created_at).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(issue.updated_at).to eq(updated_at)
      end

      it 'includes the work_item_type_id' do
        expect(issue.work_item_type_id).to eq(work_item_type_id)
      end

      it 'is not a pull request' do
        expect(issue.pull_request?).to eq(false)
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      {
        number: 42,
        title: 'My Issue',
        body: 'This is my issue',
        milestone: { number: 4 },
        state: 'open',
        assignees: [{ id: 4, login: 'alice' }],
        labels: [{ name: 'bug' }],
        user: { id: 4, login: 'alice' },
        created_at: created_at,
        updated_at: updated_at,
        pull_request: false
      }
    end

    let(:additional_data) { { work_item_type_id: work_item_type_id } }

    it_behaves_like 'an Issue' do
      let(:issue) { described_class.from_api_response(response, additional_data) }
    end

    it 'does not set the user if the response did not include a user' do
      response[:user] = nil

      issue = described_class.from_api_response(response, additional_data)

      expect(issue.author).to be_nil
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'an Issue' do
      let(:hash) do
        {
          'iid' => 42,
          'title' => 'My Issue',
          'description' => 'This is my issue',
          'milestone_number' => 4,
          'state' => 'opened',
          'assignees' => [{ 'id' => 4, 'login' => 'alice' }],
          'label_names' => %w[bug],
          'author' => { 'id' => 4, 'login' => 'alice' },
          'created_at' => created_at.to_s,
          'updated_at' => updated_at.to_s,
          'pull_request' => false,
          'work_item_type_id' => work_item_type_id
        }
      end

      let(:issue) { described_class.from_json_hash(hash) }
    end

    it 'does not convert the author if it was not specified' do
      hash = {
        'iid' => 42,
        'title' => 'My Issue',
        'description' => 'This is my issue',
        'milestone_number' => 4,
        'state' => 'opened',
        'assignees' => [{ 'id' => 4, 'login' => 'alice' }],
        'label_names' => %w[bug],
        'created_at' => created_at.to_s,
        'updated_at' => updated_at.to_s,
        'pull_request' => false
      }

      issue = described_class.from_json_hash(hash)

      expect(issue.author).to be_nil
    end
  end

  describe '#labels?' do
    it 'returns true when the issue has labels assigned' do
      issue = described_class.new(label_names: %w[bug])

      expect(issue.labels?).to eq(true)
    end

    it 'returns false when the issue has no labels assigned' do
      issue = described_class.new(label_names: [])

      expect(issue.labels?).to eq(false)
    end
  end

  describe '#pull_request?' do
    it 'returns false for an issue' do
      issue = described_class.new(pull_request: false)

      expect(issue.pull_request?).to eq(false)
    end

    it 'returns true for a pull request' do
      issue = described_class.new(pull_request: true)

      expect(issue.pull_request?).to eq(true)
    end
  end

  describe '#truncated_title' do
    it 'truncates the title to 255 characters' do
      object = described_class.new(title: 'm' * 300)

      expect(object.truncated_title.length).to eq(255)
    end

    it 'does not truncate the title if it is shorter than 255 characters' do
      object = described_class.new(title: 'foo')

      expect(object.truncated_title).to eq('foo')
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      github_identifiers = {
        iid: 42,
        issuable_type: 'MergeRequest',
        title: 'Implement cool feature'
      }
      other_attributes = { pull_request: true, something_else: '_something_else_' }
      issue = described_class.new(github_identifiers.merge(other_attributes))

      expect(issue.github_identifiers).to eq(github_identifiers)
    end
  end
end
