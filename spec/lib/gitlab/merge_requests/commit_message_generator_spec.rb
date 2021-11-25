# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::CommitMessageGenerator do
  let(:merge_commit_template) { nil }
  let(:squash_commit_template) { nil }
  let(:project) do
    create(
      :project,
      :public,
      :repository,
      merge_commit_template: merge_commit_template,
      squash_commit_template: squash_commit_template
    )
  end

  let(:user) { project.creator }
  let(:merge_request_description) { "Merge Request Description\nNext line" }
  let(:merge_request_title) { 'Bugfix' }
  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      source_project: project,
      target_project: project,
      author: user,
      description: merge_request_description,
      title: merge_request_title
    )
  end

  subject { described_class.new(merge_request: merge_request) }

  shared_examples_for 'commit message with template' do |message_template_name|
    it 'returns nil when template is not set in target project' do
      expect(result_message).to be_nil
    end

    context 'when project has custom commit template' do
      let(message_template_name) { <<~MSG.rstrip }
        %{title}

        See merge request %{reference}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end
    end

    context 'when project has commit template with closed issues' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{issues}

        See merge request %{reference}
      MSG

      it 'omits issues and new lines when no issues are mentioned in description' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when MR closes issues' do
        let(:issue_1) { create(:issue, project: project) }
        let(:issue_2) { create(:issue, project: project) }
        let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

        it 'includes them and keeps new line characters' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            Closes #{issue_1.to_reference} and #{issue_2.to_reference}

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when project has commit template with description' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{description}

        See merge request %{reference}
      MSG

      it 'uses template' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          Merge Request Description
          Next line

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end

      context 'when description is nil' do
        let(:merge_request_description) { nil }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end

      context 'when description is blank string' do
        let(:merge_request_description) { "\n\r  \n" }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when custom commit template contains placeholder in the middle or beginning of the line' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{description} %{title}

        See merge request %{reference}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Merge Request Description
          Next line Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'does not remove new line characters before empty placeholder' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

             Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when project has template with CRLF newlines' do
      let(message_template_name) do
        "Merge branch '%{source_branch}' into '%{target_branch}'\r\n\r\n%{title}\r\n\r\n%{description}\r\n\r\nSee merge request %{reference}"
      end

      it 'converts it to LF newlines' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          Merge Request Description
          Next line

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end
  end

  describe '#merge_message' do
    let(:result_message) { subject.merge_message }

    it_behaves_like 'commit message with template', :merge_commit_template
  end

  describe '#squash_message' do
    let(:result_message) { subject.squash_message }

    it_behaves_like 'commit message with template', :squash_commit_template
  end
end
