# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'have_dismissible_callout matcher', feature_category: :tooling do
  def callout_html(dismiss_endpoint:, extra_attributes: '')
    <<~HTML
      <div class="gl-alert js-persistent-callout"
        data-feature-id="some_feature"
        data-dismiss-endpoint="#{dismiss_endpoint}"
        #{extra_attributes}>
        Callout content
      </div>
    HTML
  end

  context 'with a user callout' do
    let(:html) { callout_html(dismiss_endpoint: Gitlab::Routing.url_helpers.callouts_path) }

    it 'matches on feature_id and dismiss endpoint' do
      expect(html).to have_dismissible_callout(feature_id: 'some_feature')
    end

    it 'does not match a different feature_id' do
      expect(html).not_to have_dismissible_callout(feature_id: 'other_feature')
    end

    it 'does not match when the callout class is missing' do
      html = <<~HTML
        <div class="gl-alert" data-feature-id="some_feature"
          data-dismiss-endpoint="#{Gitlab::Routing.url_helpers.callouts_path}">
        </div>
      HTML

      expect(html).not_to have_dismissible_callout(feature_id: 'some_feature')
    end

    context 'when defer_links: false is requested' do
      it 'matches a callout that omits the data-defer-links attribute' do
        expect(html).to have_dismissible_callout(feature_id: 'some_feature', defer_links: false)
      end

      it 'does not match a callout that sets data-defer-links' do
        deferred_html = callout_html(
          dismiss_endpoint: Gitlab::Routing.url_helpers.callouts_path,
          extra_attributes: 'data-defer-links="true"'
        )

        expect(deferred_html).not_to have_dismissible_callout(feature_id: 'some_feature', defer_links: false)
      end
    end
  end

  context 'with a group callout' do
    let(:group) { build_stubbed(:group) }

    let(:html) do
      callout_html(
        dismiss_endpoint: Gitlab::Routing.url_helpers.group_callouts_path,
        extra_attributes: %(data-group-id="#{group.id}" data-defer-links="true")
      )
    end

    it 'matches on group id and dismiss endpoint' do
      expect(html).to have_dismissible_callout(feature_id: 'some_feature', group: group)
    end

    it 'matches defer_links when requested' do
      expect(html).to have_dismissible_callout(feature_id: 'some_feature', group: group, defer_links: true)
    end

    it 'does not match a different group' do
      other_group = build_stubbed(:group)

      expect(html).not_to have_dismissible_callout(feature_id: 'some_feature', group: other_group)
    end
  end

  context 'when both group and project are passed' do
    let(:html) { '<div></div>' }

    it 'raises ArgumentError' do
      expect do
        expect(html).to have_dismissible_callout(
          feature_id: 'some_feature',
          group: build_stubbed(:group),
          project: build_stubbed(:project)
        )
      end.to raise_error(ArgumentError, 'pass only one of `group:` or `project:`')
    end
  end

  context 'with a project callout' do
    let(:project) { build_stubbed(:project) }

    let(:html) do
      callout_html(
        dismiss_endpoint: Gitlab::Routing.url_helpers.project_callouts_path,
        extra_attributes: %(data-project-id="#{project.id}")
      )
    end

    it 'matches on project id and dismiss endpoint' do
      expect(html).to have_dismissible_callout(feature_id: 'some_feature', project: project)
    end

    it 'does not match defer_links when the attribute is absent' do
      expect(html).not_to have_dismissible_callout(feature_id: 'some_feature', project: project, defer_links: true)
    end
  end
end
