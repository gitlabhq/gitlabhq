# frozen_string_literal: true

RSpec.shared_context 'project navbar structure' do
  include NavbarStructureHelper

  let(:secure_nav_item) do
    {
      nav_item: _('Secure'),
      nav_sub_items: [
        (_('Audit events') if Gitlab.ee?),
        _('Security configuration')
      ]
    }
  end

  let(:structure) do
    [
      {
        nav_item: _('Manage'),
        nav_sub_items: [
          _('Activity'),
          _('Members'),
          _('Labels')
        ]
      },
      {
        nav_item: _('Plan'),
        nav_sub_items: [
          _('Issues'),
          _('Issue boards'),
          _('Milestones'),
          _('Wiki')
        ]
      },
      {
        nav_item: _('Code'),
        nav_sub_items: [
          _('Merge requests'),
          _('Repository'),
          _('Branches'),
          _('Commits'),
          _('Tags'),
          _('Repository graph'),
          _('Compare revisions'),
          _('Snippets'),
          (_('Locked files') if Gitlab.ee?)
        ]
      },
      {
        nav_item: _('Build'),
        nav_sub_items: [
          _('Pipelines'),
          _('Jobs'),
          _('Pipeline editor'),
          _('Pipeline schedules'),
          _('Artifacts')
        ]
      },
      secure_nav_item,
      {
        nav_item: _('Deploy'),
        nav_sub_items: [
          _('Releases'),
          s_('FeatureFlags|Feature flags'),
          _('Model registry')
        ]
      },
      {
        nav_item: _('Operate'),
        nav_sub_items: [
          _('Environments'),
          _('Kubernetes clusters'),
          s_('Terraform|Terraform states')
        ]
      },
      {
        nav_item: _('Monitor'),
        nav_sub_items: [
          _('Error Tracking'),
          _('Alerts'),
          _('Incidents'),
          _('Service Desk')
        ]
      },
      {
        nav_item: _('Analyze'),
        nav_sub_items: project_analytics_sub_nav_item
      },
      {
        nav_item: _('Settings'),
        nav_sub_items: [
          _('General'),
          _('Integrations'),
          _('Webhooks'),
          _('Access tokens'),
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

  # Projects belonging to a group have
  # different menu elements
  let(:group_owned_structure) do
    structure.last[:nav_sub_items] = [
      _('General'),
      _('Integrations'),
      _('Webhooks'),
      _('Access tokens'),
      _('Repository'),
      _('Merge requests'),
      _('CI/CD'),
      _('Packages and registries'),
      _('Monitor'),
      _('Analytics'),
      s_('UsageQuota|Usage Quotas')
    ]
    structure
  end
end

RSpec.shared_context 'group navbar structure' do
  let(:analyze_nav_item) do
    {
      nav_item: _("Analyze"),
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
        _('Access tokens'),
        _('Projects'),
        _('Repository'),
        _('CI/CD'),
        _('Applications'),
        _('Packages and registries'),
        s_('UsageQuota|Usage Quotas'),
        _('Domain Verification')
      ]
    }
  end

  let(:settings_for_maintainer_nav_item) do
    {
      nav_item: _("Settings"),
      nav_sub_items: [_("Repository")]
    }
  end

  let(:secure_nav_item) do
    {
      nav_item: _("Secure"),
      nav_sub_items: [_("Audit events")]
    }
  end

  let(:plan_nav_items) do
    [_("Issues"), _("Issue board"), _("Milestones"), (_('Iterations') if Gitlab.ee?)]
  end

  let(:customer_relations_nav_item) do
    {
      nav_item: _('Customer relations'),
      nav_sub_items: [
        _('Contacts'),
        _('Organizations')
      ]
    }
  end

  let(:structure) do
    [
      {
        nav_item: _("Manage"),
        nav_sub_items: [_("Activity"), _("Members"), _("Labels")]
      },
      {
        nav_item: _("Plan"),
        nav_sub_items: plan_nav_items
      },
      {
        nav_item: _("Code"),
        nav_sub_items: [_("Merge requests")]
      },
      {
        nav_item: _("Build"),
        nav_sub_items: [_("Runners")]
      },
      (secure_nav_item if Gitlab.ee?),
      {
        nav_item: _("Operate"),
        nav_sub_items: [_("Kubernetes")]
      },
      (analyze_nav_item if Gitlab.ee?)
    ]
  end
end

RSpec.shared_context 'dashboard navbar structure' do
  let(:structure) do
    [
      {
        nav_item: _("Projects"),
        nav_sub_items: []
      },
      {
        nav_item: _("Groups"),
        nav_sub_items: []
      },
      {
        nav_item: _('Organizations'),
        nav_sub_items: []
      },
      {
        nav_item: _("Issues"),
        nav_sub_items: []
      },
      {
        nav_item: _("Merge requests"),
        nav_sub_items: [
          _('Assigned'),
          _('Review requests')
        ]
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
      },
      {
        nav_item: _("Import history"),
        nav_sub_items: []
      }
    ]
  end
end

RSpec.shared_context '"Explore" navbar structure' do
  let(:structure) do
    [
      {
        nav_item: _("Projects"),
        nav_sub_items: []
      },
      {
        nav_item: _("Groups"),
        nav_sub_items: []
      },
      {
        nav_item: _("CI/CD Catalog"),
        nav_sub_items: []
      },
      {
        nav_item: _("Topics"),
        nav_sub_items: []
      },
      {
        nav_item: _("Snippets"),
        nav_sub_items: []
      }
    ]
  end
end
