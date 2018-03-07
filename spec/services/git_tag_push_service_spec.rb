require 'spec_helper'

describe GitTagPushService do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { 'refs/tags/v1.1.0' }

  describe "Push tags" do
    subject do
      service.execute
      service
    end

    it 'flushes general cached data' do
      expect(project.repository).to receive(:before_push_tag)

      subject
    end

    it 'flushes the tags cache' do
      expect(project.repository).to receive(:expire_tags_cache)

      subject
    end
  end

  describe "Pipelines" do
    subject { service.execute }

    before do
      stub_ci_pipeline_to_return_yaml_file
      project.add_developer(user)
    end

    it "creates a new pipeline" do
      expect { subject }.to change { Ci::Pipeline.count }
      expect(Ci::Pipeline.last).to be_push
    end
  end

  describe "Git Tag Push Data" do
    subject { @push_data }
    let(:tag) { project.repository.find_tag(tag_name) }
    let(:commit) { tag.dereferenced_target }

    context 'annotated tag' do
      let(:tag_name) { Gitlab::Git.ref_name(ref) }

      before do
        service.execute
        @push_data = service.push_data
      end

      it { is_expected.to include(object_kind: 'tag_push') }
      it { is_expected.to include(ref: ref) }
      it { is_expected.to include(before: oldrev) }
      it { is_expected.to include(after: newrev) }
      it { is_expected.to include(message: tag.message) }
      it { is_expected.to include(user_id: user.id) }
      it { is_expected.to include(user_name: user.name) }
      it { is_expected.to include(project_id: project.id) }

      context "with repository data" do
        subject { @push_data[:repository] }

        it { is_expected.to include(name: project.name) }
        it { is_expected.to include(url: project.url_to_repo) }
        it { is_expected.to include(description: project.description) }
        it { is_expected.to include(homepage: project.web_url) }
      end

      context "with commits" do
        subject { @push_data[:commits] }

        it { is_expected.to be_an(Array) }
        it 'has 1 element' do
          expect(subject.size).to eq(1)
        end

        context "the commit" do
          subject { @push_data[:commits].first }

          it { is_expected.to include(id: commit.id) }
          it { is_expected.to include(message: commit.safe_message) }
          it { is_expected.to include(timestamp: commit.date.xmlschema) }
          it do
            is_expected.to include(
              url: [
               Gitlab.config.gitlab.url,
               project.namespace.to_param,
               project.to_param,
               'commit',
               commit.id
              ].join('/')
            )
          end

          context "with a author" do
            subject { @push_data[:commits].first[:author] }

            it { is_expected.to include(name: commit.author_name) }
            it { is_expected.to include(email: commit.author_email) }
          end
        end
      end
    end

    context 'lightweight tag' do
      let(:tag_name) { 'light-tag' }
      let(:newrev) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
      let(:ref) { "refs/tags/light-tag" }

      before do
        # Create the lightweight tag
        project.repository.raw_repository.rugged.tags.create(tag_name, newrev)

        # Clear tag list cache
        project.repository.expire_tags_cache

        service.execute
        @push_data = service.push_data
      end

      it { is_expected.to include(object_kind: 'tag_push') }
      it { is_expected.to include(ref: ref) }
      it { is_expected.to include(before: oldrev) }
      it { is_expected.to include(after: newrev) }
      it { is_expected.to include(message: tag.message) }
      it { is_expected.to include(user_id: user.id) }
      it { is_expected.to include(user_name: user.name) }
      it { is_expected.to include(project_id: project.id) }

      context "with repository data" do
        subject { @push_data[:repository] }

        it { is_expected.to include(name: project.name) }
        it { is_expected.to include(url: project.url_to_repo) }
        it { is_expected.to include(description: project.description) }
        it { is_expected.to include(homepage: project.web_url) }
      end

      context "with commits" do
        subject { @push_data[:commits] }

        it { is_expected.to be_an(Array) }
        it 'has 1 element' do
          expect(subject.size).to eq(1)
        end

        context "the commit" do
          subject { @push_data[:commits].first }

          it { is_expected.to include(id: commit.id) }
          it { is_expected.to include(message: commit.safe_message) }
          it { is_expected.to include(timestamp: commit.date.xmlschema) }
          it do
            is_expected.to include(
              url: [
               Gitlab.config.gitlab.url,
               project.namespace.to_param,
               project.to_param,
               'commit',
               commit.id
              ].join('/')
            )
          end

          context "with a author" do
            subject { @push_data[:commits].first[:author] }

            it { is_expected.to include(name: commit.author_name) }
            it { is_expected.to include(email: commit.author_email) }
          end
        end
      end
    end
  end

  describe "Webhooks" do
    context "execute webhooks" do
      let(:service) { described_class.new(project, user, oldrev: 'oldrev', newrev: 'newrev', ref: 'refs/tags/v1.0.0') }

      it "when pushing tags" do
        expect(project).to receive(:execute_hooks)
        service.execute
      end
    end
  end
end
