# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::TransformReferencesWorker, feature_category: :importers do
  let_it_be(:project) do
    project = create(:project)
    project.add_owner(user)
    project
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:bulk_import) { create(:bulk_import) }

  let_it_be(:entity) do
    create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import,
      source_full_path: 'source/full/path')
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import, url: 'https://my.gitlab.com') }

  let_it_be_with_refind(:issue) do
    create(:issue,
      project: project,
      description: 'https://my.gitlab.com/source/full/path/-/issues/1')
  end

  let_it_be(:merge_request) do
    create(:merge_request,
      source_project: project,
      description: 'https://my.gitlab.com/source/full/path/-/merge_requests/1 @source_username? @bob, @alice!')
  end

  let_it_be(:issue_note) do
    create(:note,
      noteable: issue,
      project: project,
      note: 'https://my.gitlab.com/source/full/path/-/issues/1 @older_username, not_a@username, and @old_username.')
  end

  let_it_be(:merge_request_note) do
    create(:note,
      noteable: merge_request,
      project: project,
      note: 'https://my.gitlab.com/source/full/path/-/merge_requests/1 @same_username')
  end

  let_it_be(:system_note) do
    create(:note,
      project: project,
      system: true,
      noteable: issue,
      note: "mentioned in merge request !#{merge_request.iid} created by @old_username",
      note_html: 'note html'
    )
  end

  let(:expected_url) do
    expected_url = URI('')
    expected_url.scheme = ::Gitlab.config.gitlab.https ? 'https' : 'http'
    expected_url.host = ::Gitlab.config.gitlab.host
    expected_url.port = ::Gitlab.config.gitlab.port
    expected_url.path = "/#{project.full_path}"
    expected_url
  end

  subject(:perform) { described_class.new.perform([object.id], object.class.to_s, tracker.id) }

  before do
    allow(Gitlab::Cache::Import::Caching)
      .to receive(:values_from_hash)
      .and_return({
        'old_username' => 'new_username',
        'older_username' => 'newer_username',
        'source_username' => 'destination_username',
        'bob' => 'alice-gdk',
        'alice' => 'bob-gdk',
        'manuelgrabowski' => 'manuelgrabowski-admin',
        'manuelgrabowski-admin' => 'manuelgrabowski',
        'boaty-mc-boatface' => 'boatymcboatface',
        'boatymcboatface' => 'boaty-mc-boatface'
      })
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [[issue.id], 'Issue', tracker.id] }
  end

  it 'transforms and saves multiple objects' do
    old_note = merge_request_note.note
    merge_request_note_2 = create(:note, noteable: merge_request, project: project, note: old_note)

    described_class.new.perform([merge_request_note.id, merge_request_note_2.id], 'Note', tracker.id)

    expect(merge_request_note.reload.note).not_to eq(old_note)
    expect(merge_request_note_2.reload.note).not_to eq(old_note)
  end

  it "sets the object's `importing` attribute to `true`" do
    expect_next_found_instance_of(Note) do |object|
      expect(object).to receive(:importing=).with(true)
    end

    described_class.new.perform([issue_note.id], 'Note', tracker.id)
  end

  shared_examples 'transforms and saves references' do
    it 'transforms references and saves the object' do
      expect { subject }.not_to change { object.updated_at }

      expect(body).to eq(expected_body)
    end

    context 'when an error is raised' do
      before do
        allow(BulkImports::UsersMapper).to receive(:new).and_raise(StandardError)
      end

      it 'tracks the error and creates an import failure' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(anything, hash_including(bulk_import_id: bulk_import.id))

        expect(BulkImports::Failure).to receive(:create)
          .with(hash_including(bulk_import_entity_id: entity.id, pipeline_class: 'ReferencesPipeline'))

        subject
      end
    end
  end

  context 'for issue description' do
    let(:object) { issue }
    let(:body) { object.reload.description }
    let(:expected_body) { "http://localhost:80/#{object.namespace.full_path}/-/issues/1" }

    include_examples 'transforms and saves references'

    shared_examples 'returns object unchanged' do
      it 'returns object unchanged' do
        issue.update!(description: description)

        subject

        expect(issue.reload.description).to eq(description)
      end

      it 'does not save the object' do
        expect_any_instance_of(object.class) do |object|
          expect(object).to receive(:save!)
        end

        subject
      end
    end

    context 'when object does not have reference or username' do
      let(:description) { 'foo' }

      include_examples 'returns object unchanged'
    end

    context 'when there are no matched urls or usernames' do
      let(:description) { 'https://my.gitlab.com/another/project/path/-/issues/1 @random_username' }

      include_examples 'returns object unchanged'
    end

    context 'when url path does not start with source full path' do
      let(:description) { 'https://my.gitlab.com/another/source/full/path/-/issues/1' }

      include_examples 'returns object unchanged'
    end

    context 'when host does not match and url path starts with source full path' do
      let(:description) { 'https://another.gitlab.com/source/full/path/-/issues/1' }

      include_examples 'returns object unchanged'
    end

    context 'when url does not match at all' do
      let(:description) { 'https://website.example/foo/bar' }

      include_examples 'returns object unchanged'
    end
  end

  context 'for merge request description' do
    let(:object) { merge_request }
    let(:body) { object.reload.description }
    let(:expected_body) do
      "#{expected_url}/-/merge_requests/#{merge_request.iid} @destination_username? @alice-gdk, @bob-gdk!"
    end

    include_examples 'transforms and saves references'
  end

  context 'for issue notes' do
    let(:object) { issue_note }
    let(:body) { object.reload.note }
    let(:expected_body) { "#{expected_url}/-/issues/#{issue.iid} @newer_username, not_a@username, and @new_username." }

    include_examples 'transforms and saves references'
  end

  context 'for merge request notes' do
    let(:object) { merge_request_note }
    let(:body) { object.reload.note }
    let(:expected_body) { "#{expected_url}/-/merge_requests/#{merge_request.iid} @same_username" }

    include_examples 'transforms and saves references'
  end

  context 'for system notes' do
    let(:object) { system_note }
    let(:body) { object.reload.note }
    let(:expected_body) { "mentioned in merge request !#{merge_request.iid} created by @new_username" }

    include_examples 'transforms and saves references'

    context 'when the note includes a username' do
      let_it_be(:object) do
        create(:note,
          project: project,
          system: true,
          noteable: issue,
          note: 'mentioned in merge request created by @source_username.',
          note_html: 'empty'
        )
      end

      let(:body) { object.reload.note }
      let(:expected_body) { 'mentioned in merge request created by @destination_username.' }

      include_examples 'transforms and saves references'
    end
  end

  context 'when old and new usernames are interchanged' do
    # e.g
    # |------------------------|-------------------------|
    # | old_username           | new_username            |
    # |------------------------|-------------------------|
    # | @manuelgrabowski-admin | @manuelgrabowski        |
    # | @manuelgrabowski       | @manuelgrabowski-admin  |
    # |------------------------|-------------------------|

    let_it_be(:object) do
      create(:note,
        project: project,
        noteable: merge_request,
        note: '@manuelgrabowski-admin, @boaty-mc-boatface'
      )
    end

    let(:body) { object.reload.note }
    let(:expected_body) { '@manuelgrabowski, @boatymcboatface' }

    include_examples 'transforms and saves references'
  end

  context 'when importer_user_mapping is enabled' do
    let(:object) { merge_request }
    let(:body) { object.reload.description }
    let(:expected_body) do
      "#{expected_url}/-/merge_requests/#{merge_request.iid} @source_username? @bob, @alice!"
    end

    it 'updates url references but does not map usernames in legacy manner' do
      ephemeral_data_instance = instance_double(
        Import::BulkImports::EphemeralData,
        importer_user_mapping_enabled?: true
      )
      allow(Import::BulkImports::EphemeralData)
        .to receive(:new).with(bulk_import.id)
        .and_return(ephemeral_data_instance)

      expect_any_instance_of(object.class) do |object|
        expect(object).to receive(:save!)
      end

      expect { perform }.not_to change { object.updated_at }

      expect(body).to eq(expected_body)
    end
  end
end
