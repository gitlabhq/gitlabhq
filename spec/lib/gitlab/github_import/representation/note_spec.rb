# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Representation::Note do
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  shared_examples 'a Note' do
    it 'returns an instance of Note' do
      expect(note).to be_an_instance_of(described_class)
    end

    context 'the returned Note' do
      it 'includes the noteable ID' do
        expect(note.noteable_id).to eq(42)
      end

      it 'includes the noteable type' do
        expect(note.noteable_type).to eq('Issue')
      end

      it 'includes the author details' do
        expect(note.author)
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(note.author.id).to eq(4)
        expect(note.author.login).to eq('alice')
      end

      it 'includes the note body' do
        expect(note.note).to eq('Hello world')
      end

      it 'includes the created timestamp' do
        expect(note.created_at).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(note.updated_at).to eq(updated_at)
      end

      it 'includes the GitHub ID' do
        expect(note.github_id).to eq(1)
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      double(
        :response,
        html_url: 'https://github.com/foo/bar/issues/42',
        user: double(:user, id: 4, login: 'alice'),
        body: 'Hello world',
        created_at: created_at,
        updated_at: updated_at,
        id: 1
      )
    end

    it_behaves_like 'a Note' do
      let(:note) { described_class.from_api_response(response) }
    end

    it 'does not set the user if the response did not include a user' do
      allow(response)
        .to receive(:user)
        .and_return(nil)

      note = described_class.from_api_response(response)

      expect(note.author).to be_nil
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Note' do
      let(:hash) do
        {
          'noteable_id' => 42,
          'noteable_type' => 'Issue',
          'author' => { 'id' => 4, 'login' => 'alice' },
          'note' => 'Hello world',
          'created_at' => created_at.to_s,
          'updated_at' => updated_at.to_s,
          'github_id' => 1
        }
      end

      let(:note) { described_class.from_json_hash(hash) }
    end

    it 'does not convert the author if it was not specified' do
      hash = {
        'noteable_id' => 42,
        'noteable_type' => 'Issue',
        'note' => 'Hello world',
        'created_at' => created_at.to_s,
        'updated_at' => updated_at.to_s,
        'github_id' => 1
      }

      note = described_class.from_json_hash(hash)

      expect(note.author).to be_nil
    end
  end
end
