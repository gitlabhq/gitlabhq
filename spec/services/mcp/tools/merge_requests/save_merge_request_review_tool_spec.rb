# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::SaveMergeRequestReviewTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:arguments) { {} }
  let(:tool) { described_class.new(current_user: user, params: arguments, version: '0.1.0') }

  before_all do
    project.add_developer(user)
  end

  describe 'versioning' do
    where(:method, :expected_operation_name, :expected_operation_text) do
      [
        ['create_note', 'createNote', 'mutation createMergeRequestNote'],
        ['reply_discussion', 'createNote', 'mutation createMergeRequestNote'],
        ['create_diff_note', 'createDiffNote', 'mutation createDiffNote'],
        ['resolve_discussion', 'discussionToggleResolve', 'mutation discussionToggleResolve']
      ]
    end

    with_them do
      let(:arguments) { { method: method } }

      it 'selects the operation matching the method', :aggregate_failures do
        expect(tool.operation_name).to eq(expected_operation_name)
        expect(tool.graphql_operation).to include(expected_operation_text)
      end
    end
  end

  describe '#build_variables' do
    context 'with method create_note' do
      let(:arguments) do
        {
          method: 'create_note',
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          body: 'A note',
          internal: true
        }
      end

      it 'builds a CreateNote input with the merge request global ID' do
        expect(tool.build_variables).to eq(
          input: {
            noteableId: merge_request.to_global_id.to_s,
            body: 'A note',
            internal: true
          }
        )
      end
    end

    context 'with method reply_discussion' do
      let(:arguments) do
        {
          method: 'reply_discussion',
          url: ::Gitlab::UrlBuilder.build(merge_request),
          body: 'A reply',
          discussion_id: discussion_id
        }
      end

      context 'with a bare discussion id' do
        let(:discussion_id) { 'a' * 40 }

        it 'normalizes it into a Discussion global ID' do
          expect(tool.build_variables[:input][:discussionId]).to eq("gid://gitlab/Discussion/#{'a' * 40}")
        end
      end

      context 'with a full global ID' do
        let(:discussion_id) { "gid://gitlab/Discussion/#{'b' * 40}" }

        it 'passes it through unchanged' do
          expect(tool.build_variables[:input][:discussionId]).to eq(discussion_id)
        end
      end

      context 'when the URL does not reference a merge request' do
        let(:discussion_id) { 'a' * 40 }

        before do
          arguments[:url] = "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/issues/1"
        end

        it 'raises an ArgumentError' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Invalid merge request URL/)
        end
      end
    end

    context 'with method create_diff_note' do
      let(:arguments) do
        {
          method: 'create_diff_note',
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          body: 'Inline',
          old_path: 'files/ruby/popen.rb',
          new_path: 'files/ruby/popen.rb',
          new_line: 14
        }
      end

      it 'builds the position from the merge request diff refs', :aggregate_failures do
        position = tool.build_variables[:input][:position]

        expect(position[:headSha]).to eq(merge_request.diff_refs.head_sha)
        expect(position[:startSha]).to eq(merge_request.diff_refs.start_sha)
        expect(position[:baseSha]).to eq(merge_request.diff_refs.base_sha)
        expect(position[:paths]).to eq(oldPath: 'files/ruby/popen.rb', newPath: 'files/ruby/popen.rb')
        expect(position[:newLine]).to eq(14)
        expect(position).not_to have_key(:oldLine)
      end

      it 'raises when the diff is not ready' do
        allow_next_found_instance_of(::MergeRequest) do |instance|
          allow(instance).to receive(:has_complete_diff_refs?).and_return(false)
        end

        expect { tool.build_variables }.to raise_error(ArgumentError, /diff is not ready/)
      end

      it 'raises when no path is given' do
        arguments.delete(:old_path)
        arguments.delete(:new_path)

        expect { tool.build_variables }.to raise_error(ArgumentError, %r{old_path and/or new_path})
      end

      it 'raises when no line is given' do
        arguments.delete(:new_line)

        expect { tool.build_variables }.to raise_error(ArgumentError, %r{old_line and/or new_line})
      end
    end

    context 'with method resolve_discussion' do
      let(:arguments) do
        {
          method: 'resolve_discussion',
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          discussion_id: 'c' * 40,
          resolved: false
        }
      end

      it 'builds a DiscussionToggleResolve input' do
        expect(tool.build_variables).to eq(
          input: { id: "gid://gitlab/Discussion/#{'c' * 40}", resolve: false }
        )
      end

      it 'raises when resolved is missing' do
        arguments.delete(:resolved)

        expect { tool.build_variables }.to raise_error(ArgumentError, /resolved is required/)
      end
    end

    context 'with quick actions in the body' do
      where(:body) do
        [
          ['/merge'],
          ["Looks good\n/approve"],
          ["  /close"]
        ]
      end

      with_them do
        let(:arguments) do
          {
            method: 'create_note',
            project_id: project.id.to_s,
            merge_request_iid: merge_request.iid,
            body: body
          }
        end

        it 'rejects the body' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Quick actions/)
        end
      end
    end

    context 'when identification is incomplete' do
      let(:arguments) { { method: 'create_note', body: 'x', project_id: project.id.to_s } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide either url, or project_id and merge_request_iid')
      end
    end

    context 'when the merge request is not accessible' do
      let_it_be(:private_project) { create(:project, :repository, :private) }
      let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }

      let(:arguments) do
        {
          method: 'create_note',
          project_id: private_project.id.to_s,
          merge_request_iid: private_merge_request.iid,
          body: 'A note'
        }
      end

      it 'raises the same not-found error as a nonexistent merge request' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Merge request not found/)

        arguments[:project_id] = project.id.to_s
        arguments[:merge_request_iid] = non_existing_record_iid

        expect { tool.build_variables }.to raise_error(ArgumentError, /Merge request not found/)
      end
    end
  end

  describe '#execute' do
    let(:arguments) do
      {
        method: 'create_note',
        project_id: project.id.to_s,
        merge_request_iid: merge_request.iid,
        body: 'Integration note'
      }
    end

    it 'executes the mutation as the current user', :aggregate_failures do
      allow(GitlabSchema).to receive(:execute).and_call_original

      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['method']).to eq('create_note')
      expect(result[:structuredContent]['note_id']).to eq(merge_request.notes.last.id)
      expect(result[:structuredContent]['discussion_id']).to start_with('gid://gitlab/Discussion/')
      expect(result[:structuredContent]['web_url']).to include("note_#{merge_request.notes.last.id}")

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(input: hash_including(body: 'Integration note')),
        context: hash_including(current_user: user)
      )
    end
  end
end
