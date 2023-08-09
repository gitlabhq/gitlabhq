# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateRefService, feature_category: :merge_trains do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:user) { project.creator }
    let_it_be(:first_parent_ref) { project.default_branch_or_main }
    let_it_be(:source_branch) { 'branch' }
    let(:target_ref) { "refs/merge-requests/#{merge_request.iid}/train" }
    let(:source_sha) { project.commit(source_branch).sha }
    let(:squash) { false }

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

      it 'writes the merged result into target_ref', :aggregate_failures do
        expect(result[:status]).to eq :success
        expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
          match(
            [
              a_string_matching(/Merge branch '#{source_branch}' into '#{first_parent_ref}'/),
              'Feature branch commit 2',
              'Feature branch commit 1',
              'Base parent commit 2',
              'Base parent commit 1'
            ]
          )
        )
      end

      context 'when squash is requested' do
        let(:squash) { true }

        it 'writes the squashed result', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            match(
              [
                a_string_matching(/Merge branch '#{source_branch}' into '#{first_parent_ref}'/),
                "#{merge_request.title}\n",
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      context 'when semi-linear merges are enabled' do
        before do
          project.merge_method = :rebase_merge
          project.save!
        end

        it 'writes the semi-linear merged result', :aggregate_failures do
          expect(result[:status]).to eq :success
          expect(project.repository.commits(target_ref, limit: 10, order: 'topo').map(&:message)).to(
            match(
              [
                a_string_matching(/Merge branch '#{source_branch}' into '#{first_parent_ref}'/),
                'Feature branch commit 2',
                'Feature branch commit 1',
                'Base parent commit 2',
                'Base parent commit 1'
              ]
            )
          )
        end
      end

      context 'when fast-forward merges are enabled' do
        before do
          project.merge_method = :ff
          project.save!
        end

        it 'writes the rebased merged result', :aggregate_failures do
          expect(result[:status]).to eq :success
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
    end
  end
end
