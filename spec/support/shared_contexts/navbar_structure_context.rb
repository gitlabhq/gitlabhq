# frozen_string_literal: true

RSpec.shared_context 'project navbar structure' do
  let(:analytics_nav_item) do
    {
      nav_item: _('Analytics'),
      nav_sub_items: [
        _('CI / CD'),
        (_('Code Review') if Gitlab.ee?),
        _('Repository'),
        _('Value Stream')
      ]
    }
  end

  let(:structure) do
    [
      {
        nav_item: _('Project overview'),
        nav_sub_items: [
          _('Details'),
          _('Activity'),
          _('Releases')
        ]
      },
      {
        nav_item: _('Repository'),
        nav_sub_items: [
          _('Files'),
          _('Commits'),
          _('Branches'),
          _('Tags'),
          _('Contributors'),
          _('Graph'),
          _('Compare'),
          (_('Locked Files') if Gitlab.ee?)
        ]
      },
      {
        nav_item: _('Issues'),
        nav_sub_items: [
          _('List'),
          _('Boards'),
          _('Labels'),
          _('Milestones')
        ]
      },
      {
        nav_item: _('Merge Requests'),
        nav_sub_items: []
      },
      {
        nav_item: _('CI / CD'),
        nav_sub_items: [
          _('Pipelines'),
          _('Jobs'),
          _('Artifacts'),
          _('Schedules')
        ]
      },
      {
        nav_item: _('Operations'),
        nav_sub_items: [
          _('Metrics'),
          _('Alerts'),
          _('Environments'),
          _('Error Tracking'),
          _('Serverless'),
          _('Logs'),
          _('Kubernetes')
        ]
      },
      analytics_nav_item,
      {
        nav_item: _('Wiki'),
        nav_sub_items: []
      },
      {
        nav_item: _('Snippets'),
        nav_sub_items: []
      },
      {
        nav_item: _('Settings'),
        nav_sub_items: [
          _('General'),
          _('Members'),
          _('Integrations'),
          _('Webhooks'),
          _('Repository'),
          _('CI / CD'),
          _('Operations'),
          (_('Audit Events') if Gitlab.ee?)
        ].compact
      }
    ].compact
  end
end

RSpec.shared_context 'group navbar structure' do
  let(:analytics_nav_item) do
    {
      nav_item: _('Analytics'),
      nav_sub_items: [
        _('Contribution')
      ]
    }
  end

  let(:settings_nav_item) do
    {
      nav_item: _('Settings'),
      nav_sub_items: [
        _('General'),
        _('Projects'),
        _('Repository'),
        _('CI / CD'),
        _('Integrations'),
        _('Webhooks'),
        _('Audit Events')
      ]
    }
  end

  let(:administration_nav_item) do
    {
      nav_item: _('Administration'),
      nav_sub_items: [
        s_('UsageQuota|Usage Quotas')
      ]
    }
  end

  let(:structure) do
    [
      {
        nav_item: _('Group overview'),
        nav_sub_items: [
          _('Details'),
          _('Activity')
        ]
      },
      {
        nav_item: _('Issues'),
        nav_sub_items: [
          _('List'),
          _('Board'),
          _('Labels'),
          _('Milestones')
        ]
      },
      {
        nav_item: _('Merge Requests'),
        nav_sub_items: []
      },
      {
        nav_item: _('Kubernetes'),
        nav_sub_items: []
      },
      (analytics_nav_item if Gitlab.ee?),
      {
        nav_item: _('Members'),
        nav_sub_items: []
      }
    ]
  end
end
