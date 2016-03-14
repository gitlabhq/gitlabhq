require 'spec_helper'

describe GitTagPushService, services: true do
  include RepoHelpers

  let(:user) { create :user }
  let(:project) { create :project }
  let(:service) { GitTagPushService.new }

  before do
    @oldrev = Gitlab::Git::BLANK_SHA
    @newrev = "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" # gitlab-test: git rev-parse refs/tags/v1.1.0
    @ref = 'refs/tags/v1.1.0'
  end

  describe "Git Tag Push Data" do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @push_data = service.push_data
      @tag_name = Gitlab::Git.ref_name(@ref)
      @tag = project.repository.find_tag(@tag_name)
      @commit = project.commit(@tag.target)
    end

    subject { @push_data }

    it { is_expected.to include(object_kind: 'tag_push') }
    it { is_expected.to include(ref: @ref) }
    it { is_expected.to include(before: @oldrev) }
    it { is_expected.to include(after: @newrev) }
    it { is_expected.to include(message: @tag.message) }
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

        it { is_expected.to include(id: @commit.id) }
        it { is_expected.to include(message: @commit.safe_message) }
        it { is_expected.to include(timestamp: @commit.date.xmlschema) }
        it do
          is_expected.to include(
            url: [
             Gitlab.config.gitlab.url,
             project.namespace.to_param,
             project.to_param,
             'commit',
             @commit.id
            ].join('/')
          )
        end

        context "with a author" do
          subject { @push_data[:commits].first[:author] }

          it { is_expected.to include(name: @commit.author_name) }
          it { is_expected.to include(email: @commit.author_email) }
        end
      end
    end
  end

  describe "Webhooks" do
    context "execute webhooks" do
      it "when pushing tags" do
        expect(project).to receive(:execute_hooks)
        service.execute(project, user, 'oldrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end
  end
end
