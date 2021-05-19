# frozen_string_literal: true

RSpec.shared_context 'project navbar structure' do
  let(:analytics_nav_item) do
    {
      nav_item: _('Analytics'),
      nav_sub_items: [
        _('CI/CD'),
        (_('Code Review') if Gitlab.ee?),
        (_('Merge Request') if Gitlab.ee?),
        _('Repository'),
        _('Value Stream')
      ]
    }
  end

  let(:security_and_compliance_nav_item) do
    {
      nav_item: _('Security & Compliance'),
      nav_sub_items: [
        _('Configuration'),
        (_('Audit Events') if Gitlab.ee?)
      ]
    }
  end

  let(:monitor_nav_item) do
    {
      nav_item: _('Operations'),
      nav_sub_items: monitor_menu_items
    }
  end

  let(:monitor_menu_items) do
    [
      _('Metrics'),
      _('Logs'),
      _('Tracing'),
      _('Error Tracking'),
      _('Alerts'),
      _('Incidents'),
      _('Serverless'),
      _('Terraform'),
      _('Kubernetes'),
      _('Environments'),
      _('Feature Flags'),
      _('Product Analytics')
    ]
  end

  let(:project_information_nav_item) do
    {
      nav_item: _('Project overview'),
      nav_sub_items: [
        _('Details'),
        _('Activity'),
        _('Releases')
      ]
    }
  end

  let(:settings_menu_items) do
    [
      _('General'),
      _('Integrations'),
      _('Webhooks'),
      _('Access Tokens'),
      _('Repository'),
      _('CI/CD'),
      _('Operations')
    ]
  end

  let(:structure) do
    [
      project_information_nav_item,
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
          _('Service Desk'),
          _('Milestones'),
          (_('Iterations') if Gitlab.ee?)
        ]
      },
      {
        nav_item: _('Merge requests'),
        nav_sub_items: []
      },
      {
        nav_item: _('CI/CD'),
        nav_sub_items: [
          _('Pipelines'),
          s_('Pipelines|Editor'),
          _('Jobs'),
          _('Artifacts'),
          _('Schedules')
        ]
      },
      security_and_compliance_nav_item,
      monitor_nav_item,
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
        nav_sub_items: settings_menu_items
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
        _('Integrations'),
        _('Projects'),
        _('Repository'),
        _('CI/CD'),
        _('Applications'),
        _('Packages & Registries'),
        _('Webhooks')
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

  let(:security_and_compliance_nav_item) do
    {
      nav_item: _('Security & Compliance'),
      nav_sub_items: [
        _('Audit Events')
      ]
    }
  end

  let(:push_rules_nav_item) do
    {
      nav_item: _('Push Rules'),
      nav_sub_items: []
    }
  end

  let(:group_information_nav_item) do
    {
      nav_item: _('Group information'),
      nav_sub_items: [
        _('Activity'),
        _('Labels'),
        _('Members')
      ]
    }
  end

  let(:issues_nav_items) do
    [
      _('List'),
      _('Board'),
      _('Milestones')
    ]
  end

  let(:structure) do
    [
      group_information_nav_item,
      {
        nav_item: _('Issues'),
        nav_sub_items: issues_nav_items
      },
      {
        nav_item: _('Merge requests'),
        nav_sub_items: []
      },
      security_and_compliance_nav_item,
      (push_rules_nav_item if Gitlab.ee?),
      {
        nav_item: _('Kubernetes'),
        nav_sub_items: []
      },
      (analytics_nav_item if Gitlab.ee?)
    ]
  end
end
