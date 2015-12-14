# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe Ci::MailService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end
    end
  end

  describe 'Sends email for' do
    let(:mail)   { Ci::MailService.new }
    let(:user)   { User.new(notification_email: 'git@example.com')}

    describe 'failed build' do
      let(:project) { FactoryGirl.create(:ci_project, email_add_pusher: true) }
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'failed', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        perform_enqueued_jobs do
          expect{ mail.execute(build) }.to change{ ActionMailer::Base.deliveries.size }.by(1)
          expect(ActionMailer::Base.deliveries.last.to).to eq(["git@example.com"])
        end
      end
    end

    describe 'successfull build' do
      let(:project) { FactoryGirl.create(:ci_project, email_add_pusher: true, email_only_broken_builds: false) }
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'success', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        perform_enqueued_jobs do
          expect{ mail.execute(build) }.to change{ ActionMailer::Base.deliveries.size }.by(1)
          expect(ActionMailer::Base.deliveries.last.to).to eq(["git@example.com"])
        end
      end
    end

    describe 'successfull build and project has email_recipients' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      end
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'success', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        perform_enqueued_jobs do
          expect{ mail.execute(build) }.to change{ ActionMailer::Base.deliveries.size }.by(2)
          expect(
            ActionMailer::Base.deliveries.map(&:to).flatten
          ).to include("git@example.com", "jeroen@example.com")
        end
      end
    end

    describe 'successful build and notify only broken builds' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: true,
                           email_recipients: "jeroen@example.com")
      end
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'success', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        perform_enqueued_jobs do
          expect do
            mail.execute(build) if mail.can_execute?(build)
          end.to_not change{ ActionMailer::Base.deliveries.size }
        end
      end
    end

    describe 'successful build and can test service' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      end
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'success', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
        build
      end

      it do
        expect(mail.can_test?).to eq(true)
      end
    end

    describe 'retried build should not receive email' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: true,
                           email_recipients: "jeroen@example.com")
      end
      let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, status: 'failed', commit: commit, user: user) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        Ci::Build.retry(build)
        perform_enqueued_jobs do
          expect do
            mail.execute(build) if mail.can_execute?(build)
          end.to_not change{ ActionMailer::Base.deliveries.size }
        end
      end
    end
  end
end
