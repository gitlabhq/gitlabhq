# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItemBasic, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  before_all do
    project.add_reporter(user)
  end

  describe '#user_permissions' do
    subject(:representation) do
      described_class.represent(
        work_item,
        current_user: user,
        discussion_counts: {},
        fields: %i[id title user_permissions]
      ).as_json.deep_symbolize_keys
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_work_item, work_item).and_return(true)
      allow(Ability).to receive(:allowed?).with(user, :update_work_item, work_item).and_return(false)
    end

    it 'exposes boolean permission values' do
      permissions = representation.fetch(:user_permissions)

      expect(permissions[:read_work_item]).to be(true)
      expect(permissions[:update_work_item]).to be(false)
    end
  end

  describe '#global_id' do
    it 'exposes the global id when requested' do
      representation = described_class.represent(
        work_item,
        current_user: user,
        discussion_counts: {},
        fields: %i[id global_id]
      ).as_json.deep_symbolize_keys

      expect(representation[:global_id]).to eq(work_item.to_gid.to_s)
    end
  end

  describe 'field exposures' do
    let(:base_options) do
      {
        current_user: user,
        discussion_counts: {}
      }
    end

    let(:fields) { raise 'fields must be defined for representation' }
    let(:represented_work_item) { work_item }
    let(:represent_options) { {} }

    subject(:representation) do
      described_class
        .represent(represented_work_item, base_options.merge(fields: fields).merge(represent_options))
        .as_json
        .deep_symbolize_keys
    end

    context 'when exposing the work item type' do
      let(:fields) { [:work_item_type] }

      it 'includes the type details' do
        expect(representation[:work_item_type]).to include(name: work_item.work_item_type.name)
      end
    end

    context 'when exposing the full reference' do
      let(:fields) { [:reference] }

      it 'returns the full reference' do
        expect(representation[:reference]).to eq(work_item.to_reference(full: true))
      end
    end

    context 'when exposing the create note email' do
      let(:fields) { [:create_note_email] }

      it 'uses the current user for the address' do
        allow(work_item).to receive(:creatable_note_email_address).with(user).and_return('issue-1@example.com')

        expect(representation[:create_note_email]).to eq('issue-1@example.com')
        expect(work_item).to have_received(:creatable_note_email_address).with(user)
      end
    end

    context 'when URLs are requested' do
      context 'for web_url and web_path' do
        let(:fields) { %i[web_url web_path] }

        it 'builds the URLs' do
          expect(representation[:web_url]).to eq(Gitlab::UrlBuilder.build(work_item))
          expect(representation[:web_path]).to eq(Gitlab::UrlBuilder.build(work_item, only_path: true))
        end
      end

      context 'when include_web_url is false' do
        let(:fields) { [:web_url] }
        let(:represent_options) { { include_web_url: false } }

        it 'omits the web_url' do
          expect(representation).not_to have_key(:web_url)
        end
      end

      context 'when include_web_path is false' do
        let(:fields) { [:web_path] }
        let(:represent_options) { { include_web_path: false } }

        it 'omits the web_path' do
          expect(representation).not_to have_key(:web_path)
        end
      end
    end

    context 'when presenter-backed fields are requested' do
      let(:fields) { %i[duplicated_to_work_item_url moved_to_work_item_url] }
      let(:duplicate_target) { create(:work_item, project: project) }
      let(:moved_target) { create(:work_item, project: project) }
      let(:represented_work_item) do
        create(:work_item, project: project, duplicated_to: duplicate_target, moved_to: moved_target)
      end

      it 'exposes presenter-backed URLs' do
        expect(representation[:duplicated_to_work_item_url]).to eq(Gitlab::UrlBuilder.build(duplicate_target))
        expect(representation[:moved_to_work_item_url]).to eq(Gitlab::UrlBuilder.build(moved_target))
      end
    end

    context 'when features are requested' do
      let(:fields) { [:features] }
      let(:milestone) { build(:milestone) }
      let(:widget) { instance_double(WorkItems::Widgets::Milestone, milestone: milestone) }

      before do
        allow(work_item).to receive(:has_widget?) { |widget_name| widget_name == :milestone }
        allow(work_item).to receive(:get_widget).with(:milestone).and_return(widget)
      end

      context 'with requested features' do
        let(:represent_options) { { requested_features: [:milestone] } }

        it 'exposes the features payload' do
          expect(representation[:features]).to include(:milestone)
          expect(representation[:features][:milestone]).to include(title: milestone.title)
        end
      end

      context 'without requested features' do
        let(:represent_options) { { requested_features: [] } }

        it 'omits the features payload' do
          expect(representation).not_to have_key(:features)
        end
      end
    end
  end
end
