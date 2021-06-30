# frozen_string_literal: true

RSpec.shared_context 'project navbar structure' do
  let(:security_and_compliance_nav_item) do
    {
      nav_item: _('Security & Compliance'),
      nav_sub_items: [
        (_('Audit Events') if Gitlab.ee?),
        _('Configuration')
      ]
    }
  end

  let(:structure) do
    [
      {
        nav_item: "#{project.name[0, 1].upcase} #{project.name}",
        nav_sub_items: []
      },
      {
        nav_item: _('Project information'),
        nav_sub_items: [
          _('Activity'),
          _('Labels'),
          _('Members')
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
      {
        nav_item: _('Deployments'),
        nav_sub_items: [
          _('Feature Flags'),
          _('Environments'),
          _('Releases')
        ]
      },
      {
        nav_item: _('Monitor'),
        nav_sub_items: [
          _('Metrics'),
          _('Logs'),
          _('Tracing'),
          _('Error Tracking'),
          _('Alerts'),
          _('Incidents'),
          _('Product Analytics')
        ]
      },
      {
        nav_item: _('Infrastructure'),
        nav_sub_items: [
          _('Kubernetes clusters'),
          _('Serverless platform'),
          _('Terraform')
        ]
      },
      {
        nav_item: _('Analytics'),
        nav_sub_items: [
          _('CI/CD'),
          (_('Code review') if Gitlab.ee?),
          (_('Merge request') if Gitlab.ee?),
          _('Repository'),
          _('Value stream')
        ]
      },
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
          _('Integrations'),
          _('Webhooks'),
          _('Access Tokens'),
          _('Repository'),
          _('CI/CD'),
          _('Monitor')
        ]
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

  let(:issues_nav_items) do
    [
      _('List'),
      _('Board'),
      _('Milestones')
    ]
  end

  let(:structure) do
    [
      {
        nav_item: "#{group.name[0, 1].upcase} #{group.name}",
        nav_sub_items: []
      },
      {
        nav_item: _('Group information'),
        nav_sub_items: [
          _('Activity'),
          _('Labels'),
          _('Members')
        ]
      },
      {
        nav_item: _('Issues'),
        nav_sub_items: issues_nav_items
      },
      {
        nav_item: _('Merge requests'),
        nav_sub_items: []
      },
      (security_and_compliance_nav_item if Gitlab.ee?),
      (push_rules_nav_item if Gitlab.ee?),
      {
        nav_item: _('Kubernetes'),
        nav_sub_items: []
      },
      (analytics_nav_item if Gitlab.ee?)
    ]
  end
end
