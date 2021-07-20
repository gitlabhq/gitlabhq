# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::MonitorMenu do
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

  describe '#title' do
    it 'returns "Monitor"' do
      expect(subject.title).to eq 'Monitor'
    end
  end

  describe '#extra_container_html_options' do
    it 'returns "shortcuts-monitor"' do
      expect(subject.extra_container_html_options).to eq(class: 'shortcuts-monitor')
    end
  end

  describe '#link' do
    let(:foo_path) { '/foo_path'}

    let(:foo_menu) do
      ::Sidebars::MenuItem.new(
        title: 'foo',
        link: foo_path,
        active_routes: {},
        item_id: :foo
      )
    end

    it 'returns first visible item link' do
      subject.insert_element_before(subject.renderable_items, subject.renderable_items.first.item_id, foo_menu)

      expect(subject.link).to eq foo_path
    end
  end

  context 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Metrics Dashboard' do
      let(:item_id) { :metrics }

      it_behaves_like 'access rights checks'
    end

    describe 'Logs' do
      let(:item_id) { :logs }

      it_behaves_like 'access rights checks'
    end

    describe 'Tracing' do
      let(:item_id) { :tracing }

      it_behaves_like 'access rights checks'
    end

    describe 'Error Tracking' do
      let(:item_id) { :error_tracking }

      it_behaves_like 'access rights checks'
    end

    describe 'Alert Management' do
      let(:item_id) { :alert_management }

      it_behaves_like 'access rights checks'
    end

    describe 'Incidents' do
      let(:item_id) { :incidents }

      it_behaves_like 'access rights checks'
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
