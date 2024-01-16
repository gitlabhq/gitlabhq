# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::TagHooksService, :service, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { "refs/tags/#{tag_name}" }
  let(:tag_name) { 'v1.1.0' }

  let(:tag) { project.repository.find_tag(tag_name) }
  let(:commit) { tag.dereferenced_target }

  let(:service) do
    described_class.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref })
  end

  describe 'System hooks' do
    it 'executes system hooks' do
      push_data = service.send(:push_data)
      expect(project).to receive(:has_active_hooks?).and_return(true)

      expect_next_instance_of(SystemHooksService) do |system_hooks_service|
        expect(system_hooks_service)
          .to receive(:execute_hooks)
          .with(push_data, :tag_push_hooks)
      end

      service.execute
    end
  end

  describe "Webhooks" do
    it "executes hooks on the project" do
      expect(project).to receive(:has_active_hooks?).and_return(true)
      expect(project).to receive(:execute_hooks)

      service.execute
    end
  end

  describe "Pipelines" do
    before do
      stub_ci_pipeline_to_return_yaml_file
      project.add_developer(user)
    end

    it "creates a new pipeline" do
      expect { service.execute }.to change { Ci::Pipeline.count }

      expect(Ci::Pipeline.last).to be_push
    end
  end

  describe 'Push data' do
    shared_examples_for 'tag push data expectations' do
      subject(:push_data) { service.send(:push_data) }

      it 'has expected push data attributes' do
        is_expected.to match a_hash_including(
          object_kind: 'tag_push',
          ref: ref,
          ref_protected: project.protected_for?(ref),
          before: oldrev,
          after: newrev,
          message: tag.message,
          user_id: user.id,
          user_name: user.name,
          project_id: project.id
        )
      end

      context "with repository data" do
        subject { push_data[:repository] }

        it 'has expected repository attributes' do
          is_expected.to match a_hash_including(
            name: project.name,
            url: project.url_to_repo,
            description: project.description,
            homepage: project.web_url
          )
        end
      end

      context "with commits" do
        subject { push_data[:commits] }

        it { is_expected.to be_an(Array) }

        it 'has 1 element' do
          expect(subject.size).to eq(1)
        end

        context "the commit" do
          subject { push_data[:commits].first }

          it { is_expected.to include(timestamp: commit.date.xmlschema) }

          it 'has expected commit attributes' do
            is_expected.to match a_hash_including(
              id: commit.id,
              message: commit.safe_message,
              url: [
                Gitlab.config.gitlab.url,
                project.namespace.to_param,
                project.to_param,
                '-',
                'commit',
                commit.id
              ].join('/')
            )
          end

          context "with an author" do
            subject { push_data[:commits].first[:author] }

            it 'has expected author attributes' do
              is_expected.to match a_hash_including(
                name: commit.author_name,
                email: commit.author_email
              )
            end
          end
        end
      end
    end

    context 'annotated tag' do
      include_examples 'tag push data expectations'
    end

    context 'lightweight tag' do
      let(:tag_name) { 'light-tag' }
      let(:newrev) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }

      before do
        # Create the lightweight tag
        project.repository.write_ref("refs/tags/#{tag_name}", newrev)

        # Clear tag list cache
        project.repository.expire_tags_cache
      end

      include_examples 'tag push data expectations'
    end
  end
end
