# frozen_string_literal: true

RSpec.shared_context 'project navbar structure' do
  include NavbarStructureHelper

  let(:security_and_compliance_nav_item) do
    {
      nav_item: _('Security & Compliance'),
      nav_sub_items: [
        (_('Audit events') if Gitlab.ee?),
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
          _('Milestones')
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
          _('Environments'),
          _('Feature Flags'),
          _('Releases')
        ]
      },
      {
        nav_item: _('Infrastructure'),
        nav_sub_items: [
          _('Kubernetes clusters'),
          _('Terraform')
        ]
      },
      {
        nav_item: _('Monitor'),
        nav_sub_items: [
          _('Metrics'),
          _('Error Tracking'),
          _('Alerts'),
          _('Incidents')
        ]
      },
      {
        nav_item: _('Analytics'),
        nav_sub_items: project_analytics_sub_nav_item
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
          _('Merge requests'),
          _('CI/CD'),
          _('Packages and registries'),
          _('Monitor'),
          s_('UsageQuota|Usage Quotas')
        ]
      }
    ].compact
  end
end

RSpec.shared_context 'group navbar structure' do
  let(:analytics_nav_item) do
    {
      nav_item: _('Analytics'),
      nav_sub_items: group_analytics_sub_nav_item
    }
  end

  let(:settings_nav_item) do
    {
      nav_item: _('Settings'),
      nav_sub_items: [
        _('General'),
        _('Integrations'),
        _('Webhooks'),
        _('Access Tokens'),
        _('Projects'),
        _('Repository'),
        _('CI/CD'),
        _('Applications'),
        _('Packages and registries'),
        _('Domain Verification')
      ]
    }
  end

  let(:settings_for_maintainer_nav_item) do
    {
      nav_item: _('Settings'),
      nav_sub_items: [
        _('Repository')
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
        _('Audit events')
      ]
    }
  end

  let(:ci_cd_nav_item) do
    {
      nav_item: _('CI/CD'),
      nav_sub_items: [
        s_('Runners|Runners')
      ]
    }
  end

  let(:issues_nav_items) do
    [
      _('List'),
      _('Board'),
      _('Milestones'),
      (_('Iterations') if Gitlab.ee?)
    ]
  end

  let(:structure) do
    [
      {
        nav_item: "#{group.name[0, 1].upcase} #{group.name}",
        nav_sub_items: []
      },
      {
        nav_item: group.root? ? _('Group information') : _('Subgroup information'),
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
      {
        nav_item: _('Kubernetes'),
        nav_sub_items: []
      },
      (analytics_nav_item if Gitlab.ee?)
    ]
  end
end

RSpec.shared_context 'dashboard navbar structure' do
  let(:structure) do
    [
      {
        nav_item: "Your work",
        nav_sub_items: []
      },
      {
        nav_item: _("Projects"),
        nav_sub_items: []
      },
      {
        nav_item: _("Issues"),
        nav_sub_items: []
      },
      {
        nav_item: _("Merge requests"),
        nav_sub_items: []
      },
      {
        nav_item: _("To-Do List"),
        nav_sub_items: []
      },
      {
        nav_item: _("Milestones"),
        nav_sub_items: []
      },
      {
        nav_item: _("Snippets"),
        nav_sub_items: []
      },
      {
        nav_item: _("Activity"),
        nav_sub_items: []
      }
    ]
  end
end
