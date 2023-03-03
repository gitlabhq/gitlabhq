# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicies::UpdateService, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { { cadence: '3month', keep_n: 100, older_than: '14d', extra_key: 'will_not_be_processed' } }

  let(:container_expiration_policy) { project.container_expiration_policy }

  describe '#execute' do
    subject { described_class.new(container: project, current_user: user, params: params).execute }

    RSpec.shared_examples 'returning a success' do
      it 'returns a success' do
        result = subject

        expect(result.payload[:container_expiration_policy]).to be_present
        expect(result.success?).to be_truthy
      end
    end

    RSpec.shared_examples 'returning an error' do |message, http_status|
      it 'returns an error' do
        result = subject

        expect(result.message).to eq(message)
        expect(result.status).to eq(:error)
        expect(result.http_status).to eq(http_status)
      end
    end

    RSpec.shared_examples 'updating the container expiration policy' do
      it_behaves_like 'updating the container expiration policy attributes', mode: :update, from: { cadence: '1d', keep_n: 10, older_than: '90d' }, to: { cadence: '3month', keep_n: 100, older_than: '14d' }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { cadence: '20d' } }

        it_behaves_like 'not creating the container expiration policy'

        it "doesn't update the cadence" do
          expect { subject }
            .not_to change { container_expiration_policy.reload.cadence }
        end

        it_behaves_like 'returning an error', 'Cadence is not included in the list', 400
      end
    end

    RSpec.shared_examples 'denying access to container expiration policy' do
      context 'with existing container expiration policy' do
        it_behaves_like 'not creating the container expiration policy'

        it_behaves_like 'returning an error', 'Access Denied', 403
      end
    end

    context 'with existing container expiration policy' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'updating the container expiration policy'
        :developer  | 'denying access to container expiration policy'
        :reporter   | 'denying access to container expiration policy'
        :guest      | 'denying access to container expiration policy'
        :anonymous  | 'denying access to container expiration policy'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing container expiration policy' do
      let_it_be(:project, reload: true) { create(:project, :without_container_expiration_policy) }

      where(:user_role, :shared_examples_name) do
        :maintainer | 'creating the container expiration policy'
        :developer  | 'denying access to container expiration policy'
        :reporter   | 'denying access to container expiration policy'
        :guest      | 'denying access to container expiration policy'
        :anonymous  | 'denying access to container expiration policy'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
