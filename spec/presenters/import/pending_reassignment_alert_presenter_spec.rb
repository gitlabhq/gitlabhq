# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PendingReassignmentAlertPresenter, :aggregate_failures, feature_category: :importers do
  include SafeFormatHelper

  let_it_be(:user) { build_stubbed(:user) }
  let(:bulk_import) { build_stubbed(:bulk_import, :with_configuration, :finished) }
  let(:presenter) { described_class.new(bulk_import, current_user: user) }
  let_it_be(:namespaces) { [] }

  before do
    namespaces.each do |namespace|
      allow(namespace).to receive(:owners).and_return([user])
    end

    allow(bulk_import).to receive(:namespaces_with_unassigned_placeholders).and_return(namespaces)
  end

  describe '#title' do
    subject { presenter.title }

    it { is_expected.to eq(s_('UserMapping|Placeholder users awaiting reassignment')) }
  end

  describe '#body' do
    subject { presenter.body }

    it do
      is_expected.to eq(
        safe_format(
          s_('UserMapping|Placeholder users were created in ' \
            '%{group_names}. These users were assigned group memberships and ' \
            'contributions from %{source_hostname}. To reassign contributions from ' \
            'placeholder users to GitLab users, go to the "Members" page of %{group_links}.'),
          group_names: '',
          source_hostname: 'gitlab.example',
          group_links: ''
        ))
    end
  end

  context 'with no top level groups' do
    let_it_be(:namespaces) { [] }

    it 'does not present the import values' do
      expect(presenter.show_alert?).to eq(false)
    end
  end

  context 'with one top level group' do
    let_it_be(:namespaces) do
      source_users = build_stubbed(:import_source_user)
      [build_stubbed(:group, id: 1, name: 'blink', import_source_users: [source_users])]
    end

    it 'presents the import values' do
      expect(presenter.show_alert?).to eq(true)
      expect(presenter.group_links).to eq("<a href=\"/groups/blink/-/group_members?tab=placeholders\">blink</a>")
      expect(presenter.groups_awaiting_placeholder_assignment).to match_array(namespaces)
      expect(presenter.group_names).to eq('blink')
      expect(presenter.source_hostname).to eq('gitlab.example')
    end

    context 'when importer_user_mapping feature flag is disabled' do
      before do
        stub_feature_flags(importer_user_mapping: false)
      end

      it 'does not present the import values' do
        expect(presenter.show_alert?).to eq(false)
      end
    end

    context 'when bulk_import_importer_user_mapping feature flag is disabled' do
      before do
        stub_feature_flags(bulk_import_importer_user_mapping: false)
      end

      it 'does not present the import values' do
        expect(presenter.show_alert?).to eq(false)
      end
    end

    context 'when import has not finished' do
      before do
        bulk_import.status = 1
      end

      it 'does not present the import values' do
        expect(presenter.show_alert?).to eq(false)
      end
    end
  end

  context 'with multiple top level groups' do
    let_it_be(:namespaces) do
      [
        build_stubbed(:group, id: 1, name: 'blink'),
        build_stubbed(:group, id: 3, name: 'marquee'),
        build_stubbed(:group, id: 7, name: 'details')
      ]
    end

    it 'presents the import values' do
      expect(presenter.show_alert?).to eq(true)
      expect(presenter.group_links).to eq(
        "<a href=\"/groups/blink/-/group_members?tab=placeholders\">blink</a>, " \
          "<a href=\"/groups/marquee/-/group_members?tab=placeholders\">marquee</a>, " \
          "and <a href=\"/groups/details/-/group_members?tab=placeholders\">details</a>"
      )
      expect(presenter.groups_awaiting_placeholder_assignment).to match_array(namespaces)
      expect(presenter.group_names).to eq('blink, marquee, and details')
      expect(presenter.source_hostname).to eq('gitlab.example')
    end

    context 'when the current user is not an owner of a top level group' do
      it 'excludes that group from the results' do
        allow(namespaces[0]).to receive(:owners).and_return([])

        expect(presenter.groups_awaiting_placeholder_assignment).to match_array(namespaces[1..])
      end
    end
  end
end
