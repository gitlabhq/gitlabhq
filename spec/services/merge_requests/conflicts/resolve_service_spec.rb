# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Conflicts::ResolveService, feature_category: :code_review_workflow do
  include ProjectForksHelper
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  let(:forked_project) do
    fork_project_with_submodules(project, user)
  end

  let(:merge_request) do
    create(
      :merge_request,
      source_branch: 'conflict-resolvable',
      source_project: project,
      target_branch: 'conflict-start'
    )
  end

  let(:merge_request_from_fork) do
    create(
      :merge_request,
      source_branch: 'conflict-resolvable-fork',
      source_project: forked_project,
      target_branch: 'conflict-start',
      target_project: project
    )
  end

  describe '#execute' do
    let(:service) { described_class.new(merge_request) }

    def blob_content(project, ref, path)
      project.repository.blob_at(ref, path).data
    end

    context 'with section params' do
      let(:params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              sections: {
                '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
              }
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: {
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
              }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      context 'when the source and target project are the same' do
        before do
          service.execute(user, params)
        end

        it 'creates a commit with the message' do
          expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request.source_branch_head.parents.map(&:id))
            .to eq(%w[1450cd639e0bc6721eb02800169e464f212cde06
              824be604a34828eb682305f0d963056cfac87b2d])
        end
      end

      context 'when some files have trailing newlines' do
        let!(:source_head) do
          branch = 'conflict-resolvable'
          path = 'files/ruby/popen.rb'
          popen_content = blob_content(project, branch, path)

          project.repository.update_file(
            user,
            path,
            popen_content.chomp("\n"),
            message: 'Remove trailing newline from popen.rb',
            branch_name: branch
          )
        end

        before do
          service.execute(user, params)
        end

        it 'preserves trailing newlines from our side of the conflicts' do
          head_sha = merge_request.source_branch_head.sha
          popen_content = blob_content(project, head_sha, 'files/ruby/popen.rb')
          regex_content = blob_content(project, head_sha, 'files/ruby/regex.rb')

          expect(popen_content).not_to end_with("\n")
          expect(regex_content).to end_with("\n")
        end
      end

      context 'when the source project is a fork and does not contain the HEAD of the target branch' do
        let!(:target_head) do
          project.repository.create_file(
            user,
            'new-file-in-target',
            '',
            message: 'Add new file in target',
            branch_name: 'conflict-start')
        end

        subject do
          described_class.new(merge_request_from_fork).execute(user, params)
        end

        it 'creates a commit with the message' do
          subject

          expect(merge_request_from_fork.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          subject

          expect(merge_request_from_fork.source_branch_head.parents.map(&:id))
            .to eq(['404fa3fc7c2c9b5dacff102f353bdf55b1be2813', target_head])
        end
      end
    end

    context 'with content and sections params' do
      let(:popen_content) { "class Popen\nend" }

      let(:params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: popen_content
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: {
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
              }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      before do
        service.execute(user, params)
      end

      it 'creates a commit with the message' do
        expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
      end

      it 'creates a commit with the correct parents' do
        expect(merge_request.source_branch_head.parents.map(&:id))
          .to eq(%w[1450cd639e0bc6721eb02800169e464f212cde06
            824be604a34828eb682305f0d963056cfac87b2d])
      end

      it 'sets the content to the content given' do
        blob = blob_content(
          merge_request.source_project,
          merge_request.source_branch_head.sha,
          'files/ruby/popen.rb'
        )

        expect(blob).to eq(popen_content)
      end
    end

    context 'when a resolution section is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: { '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head' }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it 'raises a ResolutionError error' do
        expect { service.execute(user, invalid_params) }
          .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)
      end
    end

    context 'when the content of a file is unchanged' do
      let(:resolver) do
        MergeRequests::Conflicts::ListService.new(merge_request).conflicts.resolver
      end

      let(:regex_conflict) do
        resolver.conflict_for_path(resolver.conflicts, 'files/ruby/regex.rb', 'files/ruby/regex.rb')
      end

      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              content: regex_conflict.content
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it 'raises a ResolutionError error' do
        expect { service.execute(user, invalid_params) }
          .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)
      end
    end

    context 'when a file is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it 'raises a ResolutionError error' do
        expect { service.execute(user, invalid_params) }
          .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)
      end
    end
  end
end
