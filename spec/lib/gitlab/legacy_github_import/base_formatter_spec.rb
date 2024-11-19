# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::BaseFormatter, feature_category: :importers do
  let_it_be(:project) { create(:project, import_type: 'gitea', namespace: create(:namespace, path: 'octocat')) }
  let(:client) { instance_double(Gitlab::LegacyGithubImport::Client) }
  let(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:imported_from) { ::Import::SOURCE_GITEA }

  let(:raw_data) do
    {
      number: 1347,
      milestone: nil,
      state: 'open',
      title: 'Found a bug',
      body: "I'm having a problem with this.",
      assignee: nil,
      user: octocat,
      comments: 0,
      pull_request: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil
    }
  end

  subject(:base) { described_class.new(project, raw_data, client) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  describe '#imported_from' do
    it 'returns the correct value for a gitea import' do
      expect(base.imported_from).to eq(:gitea)
    end

    context 'when the import type is github' do
      before do
        project.import_type = 'github'
      end

      it 'returns the correct value for a github import' do
        expect(base.imported_from).to eq(:github)
      end
    end

    context 'when the import type is unknown' do
      before do
        project.import_type = nil
      end

      it 'returns the correct value for a unknown import' do
        expect(base.imported_from).to eq(:none)
      end
    end
  end

  describe '#contributing_user_formatters' do
    it 'must be implemented in subclasses' do
      expect { base.contributing_user_formatters }.to raise_error(NotImplementedError)
    end
  end
end
