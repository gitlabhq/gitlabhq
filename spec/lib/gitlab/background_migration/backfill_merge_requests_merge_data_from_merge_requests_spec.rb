# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestsMergeDataFromMergeRequests, feature_category: :code_review_workflow do
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_requests_merge_data) { table(:merge_requests_merge_data) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let!(:organization) do
    organizations.find_or_create_by!(path: 'default') do |org|
      org.name = 'default'
    end
  end

  let!(:namespace) { namespaces.create!(name: 'test', path: 'test', organization_id: organization.id) }
  let!(:project) do
    projects.create!(
      name: 'project1',
      path: 'path1',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      visibility_level: 0,
      organization_id: organization.id
    )
  end

  let!(:user) { users.create!(email: 'test@example.com', projects_limit: 10, organization_id: organization.id) }

  subject(:perform_migration) do
    described_class.new(
      start_id: merge_requests.minimum(:id),
      end_id: merge_requests.maximum(:id),
      batch_table: :merge_requests,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    context 'when merge_requests_merge_data does not exist' do
      let!(:merge_request_1) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature',
          merge_user_id: user.id,
          merge_status: 'can_be_merged',
          merge_when_pipeline_succeeds: true,
          squash: true,
          merge_params: "---\nforce_remove_source_branch: '0'\nshould_remove_source_branch: false\n",
          merge_error: 'some error',
          merge_jid: 'job123',
          merge_commit_sha: '9998d239247cb0b08217603db09ecf68b347a31c',
          merge_ref_sha: ['e871af1e1a371b0470eb974713a1294efaa37ed2'].pack('H*'),
          squash_commit_sha: ['359e01d217a43912746589cbbc015913b6b929d9'].pack('H*'),
          in_progress_merge_commit_sha: '89e535f54ec64af94a7d704c6f2e33cd23358400',
          merged_commit_sha:
            ['36356531343837366464373230336362663439363761643465303732353138356262623737653564'].pack('H*')
        )
      end

      let!(:merge_request_2) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature2',
          merge_status: 'unchecked',
          merge_when_pipeline_succeeds: false,
          squash: false
        )
      end

      it 'creates merge_requests_merge_data records' do
        expect { perform_migration }.to change { merge_requests_merge_data.count }.from(0).to(2)
      end

      it 'correctly backfills data for merge_request_1' do
        perform_migration

        merge_data = merge_requests_merge_data.find_by(merge_request_id: merge_request_1.id)
        expect(merge_data.merge_request_id).to eq(merge_request_1.id)
        expect(merge_data.project_id).to eq(project.id)
        expect(merge_data.merge_user_id).to eq(user.id)
        expect(merge_data.merge_params).to eq(
          "---\nforce_remove_source_branch: '0'\n" \
            "should_remove_source_branch: false\n"
        )
        expect(merge_data.merge_error).to eq('some error')
        expect(merge_data.merge_jid).to eq('job123')
        expect(merge_data.merge_status).to eq(3)
        expect(merge_data.auto_merge_enabled).to be(true)
        expect(merge_data.squash).to be(true)
        # Test bytea fields that were already bytea, but storing as ASCII
        expect(merge_data.merged_commit_sha.unpack1('H*')).to eq('65e14876dd7203cbf4967ad4e0725185bbb77e5d')
        # Test bytea fields that were already bytea
        expect(merge_data.squash_commit_sha.unpack1('H*')).to eq('359e01d217a43912746589cbbc015913b6b929d9')
        expect(merge_data.merge_ref_sha.unpack1('H*')).to eq('e871af1e1a371b0470eb974713a1294efaa37ed2')
        # Test bytea fields converted from varchar
        expect(merge_data.merge_commit_sha.unpack1('H*')).to eq('9998d239247cb0b08217603db09ecf68b347a31c')
        expect(merge_data.in_progress_merge_commit_sha.unpack1('H*')).to eq('89e535f54ec64af94a7d704c6f2e33cd23358400')
      end

      it 'correctly backfills data for merge_request_2' do
        perform_migration

        merge_data = merge_requests_merge_data.find_by(merge_request_id: merge_request_2.id)

        expect(merge_data).to have_attributes(
          merge_request_id: merge_request_2.id,
          project_id: project.id,
          merge_user_id: nil,
          merge_status: 0, # 'unchecked' -> 0
          auto_merge_enabled: false,
          squash: false
        )
      end
    end

    context 'when merge_commit_sha is invalid (single character "f")' do
      let!(:merge_request_with_invalid_sha) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature-invalid',
          merge_status: 'can_be_merged',
          merge_commit_sha: 'f', # Invalid single character
          merge_user_id: user.id
        )
      end

      it 'creates merge_requests_merge_data record' do
        expect { perform_migration }.to change { merge_requests_merge_data.count }.by(1)
      end

      it 'sets merge_commit_sha to NULL for invalid value' do
        perform_migration

        merge_data = merge_requests_merge_data.find_by(merge_request_id: merge_request_with_invalid_sha.id)

        expect(merge_data).to have_attributes(
          merge_request_id: merge_request_with_invalid_sha.id,
          project_id: project.id,
          merge_user_id: user.id,
          merge_commit_sha: nil,
          merge_status: 3 # 'can_be_merged' -> 3
        )
      end
    end

    context 'when merge_requests_merge_data already exists' do
      let!(:merge_request) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature',
          merge_status: 'can_be_merged',
          merge_when_pipeline_succeeds: true,
          squash: true
        )
      end

      let!(:existing_merge_data) do
        merge_requests_merge_data.create!(
          merge_request_id: merge_request.id,
          project_id: project.id,
          merge_status: 0,
          auto_merge_enabled: false,
          squash: false
        )
      end

      it 'does not create duplicate records' do
        expect { perform_migration }.not_to change { merge_requests_merge_data.count }
      end

      it 'does not update existing records' do
        perform_migration

        merge_data = merge_requests_merge_data.find_by(merge_request_id: merge_request.id)

        expect(merge_data).to have_attributes(
          merge_status: 0,
          auto_merge_enabled: false,
          squash: false
        )
      end
    end

    context 'when some records already exist' do
      let!(:merge_request_1) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature1',
          merge_status: 'can_be_merged'
        )
      end

      let!(:merge_request_2) do
        merge_requests.create!(
          target_project_id: project.id,
          source_project_id: project.id,
          target_branch: 'main',
          source_branch: 'feature2',
          merge_status: 'checking'
        )
      end

      let!(:existing_merge_data) do
        merge_requests_merge_data.create!(
          merge_request_id: merge_request_1.id,
          project_id: project.id,
          merge_status: 0,
          auto_merge_enabled: false,
          squash: false
        )
      end

      it 'only creates missing records' do
        expect { perform_migration }.to change { merge_requests_merge_data.count }.by(1)
      end

      it 'creates the missing record correctly' do
        perform_migration

        merge_data = merge_requests_merge_data.find_by(merge_request_id: merge_request_2.id)

        expect(merge_data).to have_attributes(
          merge_request_id: merge_request_2.id,
          project_id: project.id,
          merge_status: 2 # 'checking' -> 2
        )
      end
    end

    context 'when there are no merge requests' do
      it 'does not raise an error' do
        expect { perform_migration }.not_to raise_error
      end

      it 'does not create any records' do
        expect { perform_migration }.not_to change { merge_requests_merge_data.count }
      end
    end
  end
end
