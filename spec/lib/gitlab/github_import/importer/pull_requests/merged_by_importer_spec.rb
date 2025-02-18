# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::MergedByImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be(:project) do
    create(:project, :with_import_url, :import_user_mapping_enabled, import_type: Import::SOURCE_GITHUB)
  end

  let_it_be(:merge_request) { create(:merged_merge_request, project: project) }
  let_it_be(:merger_source_user) do
    create(
      :import_source_user,
      source_user_identifier: 999,
      source_hostname: project.import_url,
      import_type: Import::SOURCE_GITHUB,
      namespace: project.root_ancestor
    )
  end

  let(:merged_at) { Time.utc(2017, 1, 1, 12) }
  let(:client_double) do
    instance_double(Gitlab::GithubImport::Client, user: { id: 999, login: 'merger', email: 'merger@email.com' })
  end

  let(:merger_user) { { id: 999, login: 'merger' } }

  let(:pull_request) do
    Gitlab::GithubImport::Representation::PullRequest.from_api_response(
      {
        number: merge_request.iid,
        merged_at: merged_at,
        merged_by: merger_user
      }
    )
  end

  subject { described_class.new(pull_request, project, client_double) }

  before do
    allow(client_double).to receive_message_chain(:octokit, :last_response, :headers).and_return({ etag: nil })
  end

  describe '#execute', :aggregate_failures do
    it 'upserts merge request metrics with merged_by details' do
      expect { subject.execute }
        .to not_change { Note.count }
        .and not_change(merge_request, :updated_at)

      metrics = merge_request.metrics.reload
      expect(metrics.merged_by_id).to eq(merger_source_user.mapped_user_id)
      expect(metrics.merged_at).to eq(merged_at)
    end

    it 'pushes placeholder references to the store' do
      subject.execute

      user_references = placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id)
      metrics = merge_request.metrics.reload

      expect(user_references).to match_array([
        ['MergeRequest::Metrics', metrics.id, 'merged_by_id', merger_source_user.id]
      ])
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
      end

      shared_examples 'adds a note referencing the merger user' do
        it 'adds a note referencing the merger user' do
          expect { subject.execute }
            .to change { Note.count }.by(1)
            .and not_change(merge_request, :updated_at)

          metrics = merge_request.metrics.reload
          expect(metrics.merged_by).to be_nil
          expect(metrics.merged_at).to eq(merged_at)

          last_note = merge_request.notes.last
          expect(last_note.created_at).to eq(merged_at)
          expect(last_note.author).to eq(project.creator)
          expect(last_note.note).to eq("*Merged by: merger at #{merged_at}*")
          expect(last_note.imported_from).to eq('github')
        end
      end

      context 'when the merger user can be mapped' do
        it 'assigns the merged by user when mapped' do
          merge_user = create(:user, email: 'merger@email.com')

          subject.execute

          metrics = merge_request.metrics.reload
          expect(metrics.merged_by).to eq(merge_user)
          expect(metrics.merged_at).to eq(merged_at)
        end
      end

      context 'when the merger user cannot be mapped to a gitlab user' do
        it_behaves_like 'adds a note referencing the merger user'

        context 'when original user cannot be found on github' do
          before do
            allow(client_double).to receive(:user).and_raise(Octokit::NotFound)
          end

          it_behaves_like 'adds a note referencing the merger user'
        end
      end

      context 'when the merger user is not provided' do
        let(:merger_user) { nil }

        it 'adds a note referencing the ghost user' do
          expect { subject.execute }
            .to change { Note.count }.by(1)
            .and not_change(merge_request, :updated_at)

          metrics = merge_request.metrics.reload
          expect(metrics.merged_by).to eq(Users::Internal.ghost)
          expect(metrics.merged_at).to eq(merged_at)

          last_note = merge_request.notes.last
          expect(last_note.created_at).to eq(merged_at)
          expect(last_note.author).to eq(project.creator)
          expect(last_note.note).to eq("*Merged by: ghost at #{merged_at}*")
        end
      end
    end
  end
end
