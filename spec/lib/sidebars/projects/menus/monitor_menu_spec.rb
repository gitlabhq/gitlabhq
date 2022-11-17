# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::MonitorMenu do
  let_it_be_with_refind(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:show_cluster_hint) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: show_cluster_hint) }

  subject { described_class.new(context) }

  describe '#render?' do
    using RSpec::Parameterized::TableSyntax
    let(:enabled) { Featurable::PRIVATE }
    let(:disabled) { Featurable::DISABLED }

    where(:flag_enabled, :operations_access_level, :monitor_level, :render) do
      true  | ref(:disabled) | ref(:enabled)  | true
      true  | ref(:disabled) | ref(:disabled) | false
      true  | ref(:enabled)  | ref(:enabled)  | true
      true  | ref(:enabled)  | ref(:disabled) | false
      false | ref(:disabled) | ref(:enabled)  | false
      false | ref(:disabled) | ref(:disabled) | false
      false | ref(:enabled)  | ref(:enabled)  | true
      false | ref(:enabled)  | ref(:disabled) | true
    end

    with_them do
      it 'renders when expected to' do
        stub_feature_flags(split_operations_visibility_permissions: flag_enabled)
        project.project_feature.update!(operations_access_level: operations_access_level)
        project.project_feature.update!(monitor_access_level: monitor_level)

        expect(subject.render?).to be render
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
  end
end
