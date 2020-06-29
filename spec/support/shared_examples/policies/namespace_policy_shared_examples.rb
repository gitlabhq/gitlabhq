# frozen_string_literal: true

RSpec.shared_examples 'update namespace limit policy' do
  describe 'update_subscription_limit' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :update_subscription_limit }

    where(:role, :is_com, :allowed) do
      :user  | true | false
      :owner | true | false
      :admin | true  | true
      :user  | false | false
      :owner | false | false
      :admin | false | false
    end

    with_them do
      let(:current_user) { build_stubbed(role) }

      before do
        allow(Gitlab).to receive(:com?).and_return(is_com)
      end

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(policy) }
      end
    end
  end
end
