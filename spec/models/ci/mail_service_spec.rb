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

describe Ci::MailService do
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
    let(:deliveries) { ActionMailer::Base.deliveries}

    before(:each) do
      deliveries.clear
    end

    describe 'failed build' do
      let(:project) { FactoryGirl.create(:ci_project, email_add_pusher: true) }
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :failed, commit: commit) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        mail.execute(build)
        expect(deliveries.count).to eq(1)
        expect(deliveries[0].subject).to include('Build failed for')
        expect(deliveries[0].to).to eq(["git@example.com"])
      end
    end

    describe 'successfull build' do
      let(:project) { FactoryGirl.create(:ci_project, email_add_pusher: true, email_only_broken_builds: false) }
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :success, commit: commit) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        mail.execute(build)
        expect(deliveries.count).to eq(1)
        expect(deliveries[0].subject).to include('Build success for')
        expect(deliveries[0].to).to eq(["git@example.com"])
      end
    end

    describe 'successfull build and project has email_recipients' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      end
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :success, commit: commit) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        mail.execute(build)
        expect(deliveries.count).to eq(2)
        expect(deliveries[0].subject).to include('Build success for')
        expect(deliveries[0].to).to eq(["jeroen@example.com"])
        expect(deliveries[1].subject).to include('Build success for')
        expect(deliveries[1].to).to eq(["git@example.com"])
      end
    end

    describe 'successful build and notify only broken builds' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: true,
                           email_recipients: "jeroen@example.com")
      end
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :success, commit: commit) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        mail.execute(build) if mail.can_execute?(build)
        expect(deliveries.count).to eq(0)
      end
    end

    describe 'successful build and can test service' do
      let(:project) do
        FactoryGirl.create(:ci_project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      end
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :success, commit: commit) }

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
      let(:commit) { FactoryGirl.create(:ci_commit, project: project) }
      let(:build) { FactoryGirl.create(:ci_build, status: :failed, commit: commit) }

      before do
        allow(mail).to receive_messages(
          project: project
        )
      end

      it do
        Ci::Build.retry(build)
        mail.execute(build) if mail.can_execute?(build)
        expect(deliveries.count).to eq(0)
      end
    end
  end
end
