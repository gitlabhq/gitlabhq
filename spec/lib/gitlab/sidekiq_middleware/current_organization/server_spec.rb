# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::CurrentOrganization::Server, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let(:test_worker) do
    Class.new do
      def self.name
        "TestWorker"
      end

      include ApplicationWorker

      cattr_accessor(:current_organization) { nil }
      cattr_accessor(:organization_source) { nil }

      def perform
        self.class.current_organization = Current.organization
        self.class.organization_source = Gitlab::ApplicationContext.current_context_attribute(:organization_source)
      end
    end
  end

  before do
    stub_const("TestWorker", test_worker)
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  describe "#call" do
    context 'when context has an organization' do
      context 'and the organization exists' do
        it 'sets Current.organization to the organization' do
          Gitlab::ApplicationContext.with_context(organization: organization) do
            TestWorker.perform_async

            expect(TestWorker.current_organization).to eq(organization)
          end
        end

        it 'sets organization_source to context in the application context' do
          Gitlab::ApplicationContext.with_context(organization: organization) do
            TestWorker.perform_async

            expect(TestWorker.organization_source).to eq('context')
          end
        end

        context 'when `track_organization_fallback` flag is disabled' do
          before do
            stub_feature_flags(track_organization_fallback: false)
          end

          it 'does not set organization_source in the application context' do
            Gitlab::ApplicationContext.with_context(organization: organization) do
              TestWorker.perform_async

              expect(TestWorker.organization_source).to be_nil
            end
          end
        end
      end

      context 'and the organization is not found' do
        it 'exits the job' do
          Gitlab::ApplicationContext.with_context(organization: build(:organization, id: non_existing_record_id)) do
            expect { TestWorker.perform_async }.to raise_error(Sidekiq::JobRetry::Skip)
          end
        end
      end
    end

    context 'when context has no organization' do
      before do
        allow(Current).to receive(:organization)
      end

      it 'does not set Current.organization' do
        Gitlab::ApplicationContext.with_context({}) do
          expect(Current).not_to receive(:organization=)

          TestWorker.perform_async
        end
      end
    end
  end
end
