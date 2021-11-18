# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InviteTeamEmailService do
  let_it_be(:user) { create(:user, email_opted_in: true) }

  let(:track) { described_class::TRACK }
  let(:series) { 0 }

  let(:setup_for_company) { true }
  let(:parent_group) { nil }
  let(:group) { create(:group, parent: parent_group) }

  subject(:action) { described_class.send_email(user, group) }

  before do
    group.add_owner(user)
    allow(group).to receive(:setup_for_company).and_return(setup_for_company)
    allow(Notify).to receive(:in_product_marketing_email).and_return(double(deliver_later: nil))
  end

  RSpec::Matchers.define :send_invite_team_email do |*args|
    match do
      expect(Notify).to have_received(:in_product_marketing_email).with(*args).once
    end

    match_when_negated do
      expect(Notify).not_to have_received(:in_product_marketing_email)
    end
  end

  shared_examples 'unexperimented' do
    it { is_expected.not_to send_invite_team_email }

    it 'does not record sent email' do
      expect { subject }.not_to change { Users::InProductMarketingEmail.count }
    end
  end

  shared_examples 'candidate' do
    it { is_expected.to send_invite_team_email(user.id, group.id, track, 0) }

    it 'records sent email' do
      expect { subject }.to change { Users::InProductMarketingEmail.count }.by(1)

      expect(
        Users::InProductMarketingEmail.where(
          user: user,
          track: track,
          series: 0
        )
      ).to exist
    end

    it_behaves_like 'tracks assignment and records the subject', :invite_team_email, :group do
      subject { group }
    end
  end

  context 'when group is in control path' do
    before do
      stub_experiments(invite_team_email: :control)
    end

    it { is_expected.not_to send_invite_team_email }

    it 'does not record sent email' do
      expect { subject }.not_to change { Users::InProductMarketingEmail.count }
    end

    it_behaves_like 'tracks assignment and records the subject', :invite_team_email, :group do
      subject { group }
    end
  end

  context 'when group is in candidate path' do
    before do
      stub_experiments(invite_team_email: :candidate)
    end

    it_behaves_like 'candidate'

    context 'when the user has not opted into marketing emails' do
      let(:user) { create(:user, email_opted_in: false ) }

      it_behaves_like 'unexperimented'
    end

    context 'when group is not top level' do
      it_behaves_like 'unexperimented' do
        let(:parent_group) do
          create(:group).tap { |g| g.add_owner(user) }
        end
      end
    end

    context 'when group is not set up for a company' do
      it_behaves_like 'unexperimented' do
        let(:setup_for_company) { nil }
      end
    end

    context 'when other users have already been added to the group' do
      before do
        group.add_developer(create(:user))
      end

      it_behaves_like 'unexperimented'
    end

    context 'when other users have already been invited to the group' do
      before do
        group.add_developer('not_a_user_yet@example.com')
      end

      it_behaves_like 'unexperimented'
    end

    context 'when the user already got sent the email' do
      before do
        create(:in_product_marketing_email, user: user, track: track, series: 0)
      end

      it_behaves_like 'unexperimented'
    end
  end
end
