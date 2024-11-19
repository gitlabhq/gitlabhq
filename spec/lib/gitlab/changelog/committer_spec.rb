# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Changelog::Committer, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:committer) { described_class.new(project, user) }
  let(:config) { Gitlab::Changelog::Config.new(project) }

  describe '#commit' do
    context "when the release isn't in the changelog" do
      it 'commits the changes' do
        release = Gitlab::Changelog::Release
          .new(version: '1.0.0', date: Time.utc(2020, 1, 1), config: config)

        committer.commit(
          release: release,
          file: 'CHANGELOG.md',
          branch: 'master',
          message: 'Test commit'
        )

        content = project.repository.blob_at('master', 'CHANGELOG.md').data

        expect(content).to eq(<<~MARKDOWN)
          ## 1.0.0 (2020-01-01)

          No changes.
        MARKDOWN
      end
    end

    context 'when the release is already in the changelog' do
      it "doesn't commit the changes" do
        release = Gitlab::Changelog::Release
          .new(version: '1.0.0', date: Time.utc(2020, 1, 1), config: config)

        2.times do
          committer.commit(
            release: release,
            file: 'CHANGELOG.md',
            branch: 'master',
            message: 'Test commit'
          )
        end

        content = project.repository.blob_at('master', 'CHANGELOG.md').data

        expect(content).to eq(<<~MARKDOWN)
          ## 1.0.0 (2020-01-01)

          No changes.
        MARKDOWN
      end
    end

    context 'when the pre-release is already in the changelog' do
      it "commits changes" do
        pre_release = Gitlab::Changelog::Release
          .new(version: '1.0.0-rc1', date: Time.utc(2020, 1, 1), config: config)

        committer.commit(
          release: pre_release,
          file: 'CHANGELOG.md',
          branch: 'master',
          message: 'Test commit'
        )

        release = Gitlab::Changelog::Release
          .new(version: '1.0.0', date: Time.utc(2020, 1, 1), config: config)

        committer.commit(
          release: release,
          file: 'CHANGELOG.md',
          branch: 'master',
          message: 'Test commit'
        )

        content = project.repository.blob_at('master', 'CHANGELOG.md').data

        expect(content).to eq(<<~MARKDOWN)
          ## 1.0.0 (2020-01-01)

          No changes.

          ## 1.0.0-rc1 (2020-01-01)

          No changes.
        MARKDOWN
      end
    end

    context 'when committing the changes fails' do
      it 'retries the operation' do
        release = Gitlab::Changelog::Release
          .new(version: '1.0.0', date: Time.utc(2020, 1, 1), config: config)

        service = instance_spy(Files::MultiService)
        errored = false

        allow(Files::MultiService)
          .to receive(:new)
          .and_return(service)

        allow(service).to receive(:execute) do
          if errored
            { status: :success }
          else
            errored = true
            { status: :error }
          end
        end

        expect do
          committer.commit(
            release: release,
            file: 'CHANGELOG.md',
            branch: 'master',
            message: 'Test commit'
          )
        end.not_to raise_error
      end
    end

    context "when the changelog changes before saving the changes" do
      it 'raises a Error' do
        release1 = Gitlab::Changelog::Release
          .new(version: '1.0.0', date: Time.utc(2020, 1, 1), config: config)

        release2 = Gitlab::Changelog::Release
          .new(version: '2.0.0', date: Time.utc(2020, 1, 1), config: config)

        # This creates the initial commit we'll later use to see if the
        # changelog changed before saving our changes.
        committer.commit(
          release: release1,
          file: 'CHANGELOG.md',
          branch: 'master',
          message: 'Initial commit'
        )

        allow(Gitlab::Git::Commit)
          .to receive(:last_for_path)
          .with(
            project.repository,
            'master',
            'CHANGELOG.md',
            literal_pathspec: true
          )
          .and_return(double(:commit, sha: 'foo'))

        expect do
          committer.commit(
            release: release2,
            file: 'CHANGELOG.md',
            branch: 'master',
            message: 'Test commit'
          )
        end.to raise_error(Gitlab::Changelog::Error)
      end
    end
  end
end
