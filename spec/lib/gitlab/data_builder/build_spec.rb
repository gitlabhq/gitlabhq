require 'spec_helper'

describe Gitlab::DataBuilder::Build do
  let(:build) { create(:ci_build) }

  describe '.build' do
    let(:data) do
      described_class.build(build)
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:ref]).to eq(build.ref) }
    it { expect(data[:sha]).to eq(build.sha) }
    it { expect(data[:tag]).to eq(build.tag) }
    it { expect(data[:build_id]).to eq(build.id) }
    it { expect(data[:build_status]).to eq(build.status) }
    it { expect(data[:build_allow_failure]).to eq(false) }
    it { expect(data[:project_id]).to eq(build.project.id) }
    it { expect(data[:project_name]).to eq(build.project.full_name) }

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
    end
  end
end
