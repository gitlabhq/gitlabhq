# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InProductMarketingCampaignEmailsService, feature_category: :activation do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:campaign) { Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE }

    before do
      allow(Notify)
        .to receive(:build_ios_app_guide_email)
        .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))
    end

    subject(:execute) do
      described_class.new(project, campaign).execute
    end

    context 'users can receive marketing emails' do
      let(:maintainer) { create(:user) }
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
        project.add_maintainer(maintainer)
      end

      it 'sends the email to all project members with access_level >= Developer', :aggregate_failures do
        [project.owner, maintainer, developer].each do |user|
          email = user.notification_email_or_default

          expect(Notify).to receive(:build_ios_app_guide_email).with(email)
        end

        execute
      end

      it 'records sent emails', :aggregate_failures do
        expect { execute }.to change { Users::InProductMarketingEmail.count }.from(0).to(3)

        [project.owner, maintainer, developer].each do |user|
          expect(
            Users::InProductMarketingEmail.where(
              user: user,
              campaign: campaign
            )
          ).to exist
        end
      end

      it 'tracks experiment :email_sent event', :experiment do
        expect(experiment(:build_ios_app_guide_email)).to track(:email_sent)
          .on_next_instance
          .with_context(project: project)

        execute
      end
    end

    shared_examples 'does not send the email' do
      it do
        email = user.notification_email_or_default
        expect(Notify).not_to receive(:build_ios_app_guide_email).with(email)
        execute
      end
    end

    shared_examples 'does not create a record of the sent email' do
      it do
        expect(
          Users::InProductMarketingEmail.where(
            user: user,
            campaign: campaign
          )
        ).not_to exist

        execute
      end
    end

    context "when user can't receive marketing emails" do
      before do
        project.add_developer(user)
      end

      context 'when user.can?(:receive_notifications) is false' do
        it 'does not send the email' do
          allow_next_found_instance_of(User) do |user|
            allow(user).to receive(:can?).with(:receive_notifications) { false }

            email = user.notification_email_or_default
            expect(Notify).not_to receive(:build_ios_app_guide_email).with(email)

            expect(
              Users::InProductMarketingEmail.where(
                user: user,
                campaign: campaign
              )
            ).not_to exist
          end

          execute
        end
      end
    end

    context 'when campaign email has already been sent to the user' do
      before do
        project.add_developer(user)
        create(:in_product_marketing_email, :campaign, user: user, campaign: campaign)
      end

      it_behaves_like 'does not send the email'
    end

    context "when user is a reporter" do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'does not send the email'
      it_behaves_like 'does not create a record of the sent email'
    end

    context "when user is a guest" do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'does not send the email'
      it_behaves_like 'does not create a record of the sent email'
    end
  end
end
