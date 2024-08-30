# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require 'gitlab/rspec/all'
require_relative '../../scripts/generate-message-to-run-e2e-pipeline'

RSpec.describe GenerateMessageToRunE2ePipeline, feature_category: :tooling do
  include StubENV

  let(:options) do
    {
      project: '13083',
      pipeline_id: '13083',
      api_token: 'asdf1234',
      endpoint: 'https://gitlab.com/api/v4'
    }
  end

  let(:client) { double('Gitlab::Client') }

  let(:note_content) do
    <<~MARKDOWN
      <!-- Run e2e warning begin -->
      Some note
      <!-- Run e2e warning end -->
    MARKDOWN
  end

  before do
    allow(Gitlab).to receive(:client)
                       .with(endpoint: options[:endpoint], private_token: options[:api_token])
                       .and_return(client)
  end

  subject { described_class.new(options) }

  describe '#execute' do
    let(:commit_merge_request) do
      Struct.new(:author, :iid).new(
        Struct.new(:id, :username).new(
          '2',
          'test_user'
        ),
        '123'
      )
    end

    let(:merge_request) { instance_double(CommitMergeRequests, execute: [commit_merge_request]) }
    let(:merge_request_note_client) { instance_double(CreateMergeRequestNote, execute: true) }

    before do
      stub_env(
        'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => 'bfcd2b9b5cad0b889494ce830697392c8ca11257'
      )

      allow(CommitMergeRequests).to receive(:new)
                                      .with(options.merge(sha: ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA']))
                                      .and_return(merge_request)
    end

    context 'when there are qa_test_folders' do
      before do
        allow(subject).to receive(:qa_tests_folders?).and_return(true)
      end

      context 'when there is no existing note' do
        before do
          allow(subject).to receive(:existing_note).and_return(nil)
          allow(subject).to receive(:content).and_return(note_content)

          allow(client).to receive(:create_merge_request_comment)
                             .with(options[:project], '123', note_content)
        end

        it 'adds a new note' do
          expect(CreateMergeRequestNote).to receive(:new)
                                              .with(options.merge(merge_request: commit_merge_request))
                                              .and_return(merge_request_note_client)

          expect(merge_request_note_client).to receive(:execute).with(note_content)

          subject.execute
        end
      end

      context 'when there is existing note' do
        before do
          allow(subject).to receive(:existing_note).and_return(true)
        end

        it 'does not add a new note' do
          expect(CreateMergeRequestNote).not_to receive(:new)

          subject.execute
        end
      end
    end

    context 'when there are no qa_test_folders' do
      before do
        allow(subject).to receive(:qa_tests_folders?).and_return(false)
      end

      it 'does not add a new note' do
        expect(CreateMergeRequestNote).not_to receive(:new)

        subject.execute
      end
    end
  end

  describe '#qa_tests_folders?' do
    before do
      allow(File).to receive(:exist?).with(any_args).and_return(true)
      allow(File).to receive(:open).with(any_args).and_return(file_contents)
    end

    context 'when QA_TESTS is empty' do
      let(:file_contents) do
        %w[
          QA_SUITES='QA::Scenario::Test::Instance::All'
          QA_TESTS=''
          QA_FEATURE_FLAGS=''
        ]
      end

      it 'returns false' do
        expect(subject.send(:qa_tests_folders?)).to be_falsy
      end
    end

    context 'when QA_TESTS has a spec file' do
      let(:file_contents) do
        %w[
          QA_SUITES='QA::Scenario::Test::Instance::All'
          QA_TESTS='qa/specs/features/browser_ui/1_manage/login/log_in_spec.rb'
          QA_FEATURE_FLAGS=''
        ]
      end

      it 'returns false' do
        expect(subject.send(:qa_tests_folders?)).to be_falsy
      end
    end

    context 'when QA_TESTS has folders' do
      let(:file_contents) do
        [
          "QA_SUITES='QA::Scenario::Test::Instance::All'",
          "QA_TESTS='qa/specs/features/browser_ui/1_manage/ qa/specs/features/browser_ui/2_plan'",
          "QA_FEATURE_FLAGS=''"
        ]
      end

      it 'returns true' do
        expect(subject.send(:qa_tests_folders?)).to be_truthy
      end
    end
  end

  describe '#match?' do
    it 'returns true for a note that matches NOTE_PATTERN' do
      expect(subject.send(:match?, note_content)).to be_truthy
    end

    it 'returns false for a note that does not match NOTE_PATTERN' do
      expect(subject.send(:match?, 'Some random text')).to be_falsy
    end
  end

  describe '#existing_note' do
    let(:mr_comments_response) do
      [
        double(:mr_comment, id: 1, body: 'foo'),
        double(:mr_comment, id: 2, body: 'bar'),
        existing_note
      ]
    end

    before do
      allow(client)
        .to receive(:merge_request_comments)
              .with(any_args)
              .and_return(double(auto_paginate: mr_comments_response))
      allow(subject).to receive(:merge_request).and_return(double(:merge_request, id: 2, iid: 123))
    end

    context 'when note exists' do
      let(:existing_note) do
        double(
          :mr_comment,
          id: 3,
          body: note_content
        )
      end

      it 'returns the existing note' do
        expect(subject.send(:existing_note)).to eq existing_note
      end
    end

    context 'when note doesnt exists' do
      let(:existing_note) do
        double(
          :mr_comment,
          id: 3,
          body: 'random content'
        )
      end

      it 'returns nil' do
        expect(subject.send(:existing_note)).to eq nil
      end
    end
  end

  describe '#content' do
    let(:author_username) { 'sam_smith' }

    let(:expected_content) do
      <<~MARKDOWN
      <!-- Run e2e warning begin -->
      @#{author_username} Some end-to-end (E2E) tests should run based on the stage label.

      Please start the `manual:e2e-test-pipeline-generate` job in the `prepare` stage and wait for the tests in the `follow-up:e2e:test-on-omnibus-ee` pipeline
      to pass **before merging this MR**. Do not use **Auto-merge**, unless these tests have already completed successfully, because a failure in these tests do not block the auto-merge.
      (E2E tests are computationally intensive and don't run automatically for every push/rebase, so we ask you to run this job manually at least once.)

      To run all E2E tests, apply the ~"pipeline:run-all-e2e" label and run a new pipeline.

      E2E test jobs are allowed to fail due to [flakiness](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/dashboards).
      See current failures at the latest [pipeline triage issue](https://gitlab.com/gitlab-org/quality/pipeline-triage/-/issues).

      Once done, apply the ✅ emoji on this comment.

      **Team members only:** for any questions or help, reach out on the internal `#test-platform` Slack channel.
      <!-- Run e2e warning end -->
      MARKDOWN
    end

    before do
      allow(subject).to receive(:merge_request).and_return(double(:merge_request,
        author: double(username: author_username)))
    end

    it 'returns content text with author username' do
      expect(subject.send(:content)).to eq expected_content
    end
  end

  describe '#author_username' do
    let(:author_username) { 'sam_smith' }

    before do
      allow(subject).to receive(:merge_request).and_return(double(:merge_request,
        author: double(username: author_username)))
    end

    it 'returns nil' do
      expect(subject.send(:author_username)).to eq author_username
    end
  end

  describe '#env' do
    before do
      stub_env(
        'VAR_WITH_VALUE' => 'bfcd2b9b5cad0b889494ce830697392c8ca11257',
        'EMPTY_VAR' => ' '
      )
    end

    it 'returns env var when not empty' do
      expect(subject.send(:env, 'VAR_WITH_VALUE')).to eq 'bfcd2b9b5cad0b889494ce830697392c8ca11257'
    end

    it 'returns nil when env var is empty' do
      expect(subject.send(:env, 'EMPTY_VAR')).to be_nil
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
