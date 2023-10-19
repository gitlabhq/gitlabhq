# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateRefService, feature_category: :merge_trains do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :empty_repo) }
    let_it_be(:user) { project.creator }
    let_it_be(:first_parent_ref) { project.default_branch_or_main }
    let_it_be(:source_branch) { 'branch' }
    let(:target_ref) { "refs/merge-requests/#{merge_request.iid}/train" }
    let(:source_sha) { project.commit(source_branch).sha }
    let(:squash) { false }
    let(:default_commit_message) { merge_request.default_merge_commit_message(user: user) }

    let(:merge_request) do
      create(
        :merge_request,
        title: 'Merge request ref test',
        author: user,
        source_project: project,
        target_project: project,
        source_branch: source_branch,
        target_branch: first_parent_ref,
        squash: squash
      )
    end

    subject(:result) do
      described_class.new(
        current_user: user,
        merge_request: merge_request,
        target_ref: target_ref,
        source_sha: source_sha,
        first_parent_ref: first_parent_ref
      ).execute
    end

    context 'when there is a user-caused gitaly error' do
      let(:source_sha) { '123' }

      it 'returns an error response' do
        expect(result[:status]).to eq :error
      end
    end

    context 'with valid inputs' do
      before_all do
        # ensure first_parent_ref is created before source_sha
        project.repository.create_file(
          user,
          'README.md',
          '',
          message: 'Base parent commit 1',
          branch_name: first_parent_ref
        )
        project.repository.create_branch(source_branch, first_parent_ref)

        # create two commits source_branch to test squashing
        project.repository.create_file(
          user,
          '.gitlab-ci.yml',
          '',
          message: 'Feature branch commit 1',
          branch_name: source_branch
        )

        project.repository.create_file(
          user,
          '.gitignore',
          '',
          message: 'Feature branch commit 2',
          branch_name: source_branch
        )

        # create an extra commit not present on source_branch
        project.repository.create_file(
          user,
          'EXTRA',
          '',
          message: 'Base parent commit 2',
          branch_name: first_parent_ref
        )
      end

      shared_examples_for 'writing with a merge commit' do
        it 'merges with a merge commit', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(result[:commit_sha]).to eq(project.repository.commit(target_ref).sha)
          expect(result[:source_sha]).to eq(project.repository.commit(source_branch).sha)
          expect(result[:target_sha]).to eq(project.repository.commit(first_parent_ref).sha)
          expect(result[:merge_commit_sha]).to be_present
          expect(result[:squash_commit_sha]).not_to be_present
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            match(
              [
                expected_merge_commit,
                'Feature branch commit 2',
                'Feature branch commit 1',
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      shared_examples_for 'writing with a squash and merge commit' do
        it 'writes the squashed result', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(result[:commit_sha]).to eq(project.repository.commit(target_ref).sha)
          expect(result[:source_sha]).to eq(project.repository.commit(source_branch).sha)
          expect(result[:target_sha]).to eq(project.repository.commit(first_parent_ref).sha)
          expect(result[:merge_commit_sha]).to be_present
          expect(result[:squash_commit_sha]).to be_present
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            match(
              [
                expected_merge_commit,
                "#{merge_request.title}\n",
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      shared_examples_for 'writing with a squash and no merge commit' do
        it 'writes the squashed result without a merge commit', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(result[:commit_sha]).to eq(project.repository.commit(target_ref).sha)
          expect(result[:source_sha]).to eq(project.repository.commit(source_branch).sha)
          expect(result[:target_sha]).to eq(project.repository.commit(first_parent_ref).sha)
          expect(result[:merge_commit_sha]).not_to be_present
          expect(result[:squash_commit_sha]).to be_present
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            match(
              [
                "#{merge_request.title}\n",
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      shared_examples_for 'writing without a merge commit' do
        it 'writes the rebased merged result', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(result[:commit_sha]).to eq(project.repository.commit(target_ref).sha)
          expect(result[:source_sha]).to eq(project.repository.commit(source_branch).sha)
          expect(result[:target_sha]).to eq(project.repository.commit(first_parent_ref).sha)
          expect(result[:merge_commit_sha]).not_to be_present
          expect(result[:squash_commit_sha]).not_to be_present
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            eq(
              [
                'Feature branch commit 2',
                'Feature branch commit 1',
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      shared_examples 'merge commits without squash' do
        context 'with a custom template' do
          let(:expected_merge_commit) { 'This is the merge commit' } # could also be default_commit_message

          before do
            project.project_setting.update!(merge_commit_template: expected_merge_commit)
          end

          it_behaves_like 'writing with a merge commit'
        end

        context 'with no custom template' do
          let(:expected_merge_commit) { default_commit_message }

          before do
            project.project_setting.update!(merge_commit_template: nil)
          end

          it_behaves_like 'writing with a merge commit'
        end
      end

      shared_examples 'merge commits with squash' do
        context 'when squash set' do
          let(:squash) { true }
          let(:expected_merge_commit) { merge_request.default_merge_commit_message(user: user) }

          before do
            project.project_setting.update!(merge_commit_template: 'This is the merge commit')
          end

          it_behaves_like 'writing with a squash and merge commit'
        end
      end

      context 'when the merge commit message is provided at time of merge' do
        let(:expected_merge_commit) { 'something custom' }

        before do
          merge_request.merge_params['commit_message'] = expected_merge_commit
        end

        it 'writes the merged result', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(project.repository.commits(target_ref, limit: 1, order: 'topo').map(&:message)).to(
            match([expected_merge_commit])
          )
        end

        context 'when squash set' do
          let(:squash) { true }

          it_behaves_like 'writing with a squash and merge commit'
        end
      end

      context 'when merged commit strategy' do
        include_examples 'merge commits without squash'
        include_examples 'merge commits with squash'
      end

      context 'when semi-linear merge strategy' do
        before do
          project.merge_method = :rebase_merge
          project.save!
        end

        include_examples 'merge commits without squash'
        include_examples 'merge commits with squash'

        context 'when the target ref changes between rebase and merge' do
          # this tests internal handling of expected_old_oid

          it 'returns an error', :aggregate_failures do
            expect_next_instance_of(described_class) do |instance|
              original = instance.method(:maybe_merge!)

              expect(instance).to receive(:maybe_merge!) do |*args, **kwargs|
                # Corrupt target_ref before the merge, simulating a race with
                # another instance of the service for the same MR. source_sha is
                # just an arbitrary valid commit that differs from what was just
                # written.
                project.repository.write_ref(target_ref, source_sha)
                original.call(*args, **kwargs)
              end
            end

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq "9:Could not update #{target_ref}. Please refresh and try again."
          end
        end
      end

      context 'when fast-forward merge strategy' do
        before do
          project.merge_method = :ff
          project.save!
        end

        it_behaves_like 'writing without a merge commit'

        context 'when squash set' do
          let(:squash) { true }

          it_behaves_like 'writing with a squash and no merge commit'
        end
      end
    end
  end
end
