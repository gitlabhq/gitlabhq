# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserAgentDetailService, feature_category: :instance_resiliency do
  describe '#create', :request_store do
    let_it_be(:spammable) { create(:issue) }
    let_it_be(:current_user) { create(:user) }

    using RSpec::Parameterized::TableSyntax

    where(:perform_spam_check, :spam_params_present, :user_agent, :ip_address, :creates_user_agent_detail) do
      true  | true  | 'UA' | 'IP' | true
      true  | false | 'UA' | 'IP' | false
      false | true  | 'UA' | 'IP' | false
      true  | true  | ''   | 'IP' | false
      true  | true  | nil  | 'IP' | false
      true  | true  | 'UA' | ''   | false
      true  | true  | 'UA' | nil  | false
    end

    with_them do
      subject(:service) do
        described_class.new(
          spammable: spammable,
          perform_spam_check: perform_spam_check,
          current_user: current_user
        )
      end

      let(:spam_params) do
        instance_double('Spam::SpamParams', user_agent: user_agent, ip_address: ip_address) if spam_params_present
      end

      before do
        allow(Gitlab::RequestContext.instance).to receive(:spam_params).and_return(spam_params)
      end

      if params[:creates_user_agent_detail]
        it { expect { expect(service.create).to be_a(UserAgentDetail) }.to change { UserAgentDetail.count }.by(1) }
      else
        it { expect(service.create).to be_a ServiceResponse }
      end
    end
  end
end
