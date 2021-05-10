# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::OperationsMenu do
  let_it_be_with_refind(:project) { create(:project) }

  let(:user) { project.owner }
  let(:show_cluster_hint) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: show_cluster_hint) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when operations feature is disabled' do
      it 'returns false' do
        project.project_feature.update!(operations_access_level: Featurable::DISABLED)

        expect(subject.render?).to be false
      end
    end

    context 'when operation feature is enabled' do
      context 'when menu does not have any renderable menu items' do
        it 'returns false' do
          allow(subject).to receive(:has_renderable_items?).and_return(false)

          expect(subject.render?).to be false
        end
      end

      context 'when menu has menu items' do
        it 'returns true' do
          expect(subject.render?).to be true
        end
      end
    end
  end

  describe '#link' do
    context 'when metrics dashboard is visible' do
      it 'returns link to the metrics dashboard page' do
        expect(subject.link).to include('/-/environments/metrics')
      end
    end

    context 'when metrics dashboard is not visible' do
      it 'returns link to the feature flags page' do
        project.project_feature.update!(operations_access_level: Featurable::DISABLED)

        expect(subject.link).to include('/-/feature_flags')
      end
    end
  end

  context 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Metrics Dashboard' do
      let(:item_id) { :metrics }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Logs' do
      let(:item_id) { :logs }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Tracing' do
      let(:item_id) { :tracing }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Error Tracking' do
      let(:item_id) { :error_tracking }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Alert Management' do
      let(:item_id) { :alert_management }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Incidents' do
      let(:item_id) { :incidents }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Serverless' do
      let(:item_id) { :serverless }

      context 'when feature flag :sidebar_refactor is enabled' do
        specify { is_expected.to be_nil }
      end

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        specify { is_expected.not_to be_nil }

        describe 'when the user does not have access' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Terraform' do
      let(:item_id) { :terraform }

      context 'when feature flag :sidebar_refactor is enabled' do
        specify { is_expected.to be_nil }
      end

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        specify { is_expected.not_to be_nil }

        describe 'when the user does not have access' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Kubernetes' do
      let(:item_id) { :kubernetes }

      context 'when feature flag :sidebar_refactor is enabled' do
        specify { is_expected.to be_nil }
      end

      context 'when feature flag :sidebar_refactor is disabled' do
        before do
          stub_feature_flags(sidebar_refactor: false)
        end

        specify { is_expected.not_to be_nil }

        describe 'when the user does not have access' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Environments' do
      let(:item_id) { :environments }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Feature Flags' do
      let(:item_id) { :feature_flags }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Product Analytics' do
      let(:item_id) { :product_analytics }

      specify { is_expected.not_to be_nil }

      describe 'when feature flag :product_analytics is disabled' do
        specify do
          stub_feature_flags(product_analytics: false)

          is_expected.to be_nil
        end
      end
    end
  end
end
