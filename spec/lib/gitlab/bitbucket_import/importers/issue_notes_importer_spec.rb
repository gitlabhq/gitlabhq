# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::IssueNotesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started, import_source: 'namespace/repo',
      import_data_attributes: {
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let_it_be(:bitbucket_user) { create(:user) }
  let_it_be(:identity) { create(:identity, user: bitbucket_user, extern_uid: '{123}', provider: :bitbucket) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:hash) { { iid: issue.iid } }
  let(:note_body) { 'body' }
  let(:client) { Bitbucket::Client.new({}) }
  let(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket', project) }

  subject(:importer) { described_class.new(project, hash) }

  describe '#execute' do
    let(:issue_comments_response) do
      [
        Bitbucket::Representation::Comment.new({
          'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
          'content' => { 'raw' => note_body },
          'created_on' => Date.today,
          'updated_on' => Date.today
        })
      ]
    end

    before do
      allow(Bitbucket::Client).to receive(:new).and_return(client)
      allow(client).to receive(:issue_comments).and_return(issue_comments_response)
      allow(Gitlab::Import::MentionsConverter).to receive(:new).and_return(mentions_converter)
    end

    it 'creates a new note with the correct attributes' do
      expect { importer.execute }.to change { issue.notes.count }.from(0).to(1)

      note = issue.notes.first

      expect(note.project).to eq(project)
      expect(note.note).to eq(note_body)
      expect(note.author).to eq(bitbucket_user)
      expect(note.created_at).to eq(Date.today)
      expect(note.updated_at).to eq(Date.today)
      expect(note.imported_from).to eq('bitbucket')
    end

    it 'converts mentions in the note' do
      expect(mentions_converter).to receive(:convert).once.and_call_original

      importer.execute
    end

    context 'when the author does not have a bitbucket identity' do
      before do
        identity.update!(provider: :github)
      end

      it 'sets the author to the project creator and adds the author to the note' do
        importer.execute

        note = issue.notes.first

        expect(note.author).to eq(project.creator)
        expect(note.note).to eq("*Created by: bitbucket_user*\n\nbody")
      end
    end

    it 'calls RefConverter to convert Bitbucket refs to Gitlab refs' do
      expect(importer.instance_values['ref_converter']).to receive(:convert_note).once

      importer.execute
    end

    context 'when an error is raised' do
      before do
        allow(client).to receive(:issue_comments).and_raise(StandardError)
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        importer.execute
      end
    end
  end
end
