# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Build do
  let!(:tag_names) { %w(tag-1 tag-2) }
  let(:runner) { create(:ci_runner, :instance, tag_list: tag_names.map { |n| ActsAsTaggableOn::Tag.create!(name: n)}) }
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, :running, runner: runner, user: user) }

  describe '.build' do
    around do |example|
      travel_to(Time.current) { example.run }
    end

    let(:data) do
      described_class.build(build)
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:ref]).to eq(build.ref) }
    it { expect(data[:sha]).to eq(build.sha) }
    it { expect(data[:tag]).to eq(build.tag) }
    it { expect(data[:build_id]).to eq(build.id) }
    it { expect(data[:build_status]).to eq(build.status) }
    it { expect(data[:build_created_at]).to eq(build.created_at) }
    it { expect(data[:build_started_at]).to eq(build.started_at) }
    it { expect(data[:build_finished_at]).to eq(build.finished_at) }
    it { expect(data[:build_duration]).to eq(build.duration) }
    it { expect(data[:build_queued_duration]).to eq(build.queued_duration) }
    it { expect(data[:build_allow_failure]).to eq(false) }
    it { expect(data[:build_failure_reason]).to eq(build.failure_reason) }
    it { expect(data[:project_id]).to eq(build.project.id) }
    it { expect(data[:project_name]).to eq(build.project.full_name) }
    it { expect(data[:pipeline_id]).to eq(build.pipeline.id) }
    it {
      expect(data[:user]).to eq(
        {
            id: user.id,
            name: user.name,
            username: user.username,
            avatar_url: user.avatar_url(only_path: false),
            email: user.email
            })
    }
    it { expect(data[:commit][:id]).to eq(build.pipeline.id) }
    it { expect(data[:runner][:id]).to eq(build.runner.id) }
    it { expect(data[:runner][:tags]).to match_array(tag_names) }
    it { expect(data[:runner][:description]).to eq(build.runner.description) }
    it { expect(data[:runner][:runner_type]).to eq(build.runner.runner_type) }
    it { expect(data[:runner][:is_shared]).to eq(build.runner.instance_type?) }
    it { expect(data[:environment]).to be_nil }

    context 'commit author_url' do
      context 'when no commit present' do
        let(:build) { create(:ci_build) }

        it 'sets to mailing address of git_author_email' do
          expect(data[:commit][:author_url]).to eq("mailto:#{build.pipeline.git_author_email}")
        end
      end

      context 'when commit present but has no author' do
        let(:build) { create(:ci_build, :with_commit) }

        it 'sets to mailing address of git_author_email' do
          expect(data[:commit][:author_url]).to eq("mailto:#{build.pipeline.git_author_email}")
        end
      end

      context 'when commit and author are present' do
        let(:build) { create(:ci_build, :with_commit_and_author) }

        it 'sets to GitLab user url' do
          expect(data[:commit][:author_url]).to eq(Gitlab::Routing.url_helpers.user_url(username: build.commit.author.username))
        end
      end

      context 'with environment' do
        let(:build) { create(:ci_build, :teardown_environment) }

        it { expect(data[:environment][:name]).to eq(build.expanded_environment_name) }
        it { expect(data[:environment][:action]).to eq(build.environment_action) }
      end
    end
  end
end
