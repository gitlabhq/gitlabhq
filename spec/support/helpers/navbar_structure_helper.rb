# frozen_string_literal: true

module NavbarStructureHelper
  def insert_after_nav_item(before_nav_item_name, new_nav_item:)
    expect(structure).to include(a_hash_including(nav_item: before_nav_item_name))

    index = structure.find_index { |h| h[:nav_item] == before_nav_item_name if h }
    structure.insert(index + 1, new_nav_item)
  end

  def insert_before_nav_item(after_nav_item_name, new_nav_item:)
    expect(structure).to include(a_hash_including(nav_item: after_nav_item_name))

    index = structure.find_index { |h| h[:nav_item] == after_nav_item_name if h }
    structure.insert(index, new_nav_item)
  end

  def insert_after_sub_nav_item(before_sub_nav_item_name, within:, new_sub_nav_item_name:)
    expect(structure).to include(a_hash_including(nav_item: within))
    hash = structure.find { |h| h[:nav_item] == within if h }

    expect(hash).to have_key(:nav_sub_items)
    expect(hash[:nav_sub_items]).to include(before_sub_nav_item_name)

    index = hash[:nav_sub_items].find_index(before_sub_nav_item_name)
    hash[:nav_sub_items].insert(index + 1, new_sub_nav_item_name)
  end

  def insert_before_sub_nav_item(after_sub_nav_item_name, within:, new_sub_nav_item_name:)
    expect(structure).to include(a_hash_including(nav_item: within))
    hash = structure.find { |h| h[:nav_item] == within if h }

    expect(hash).to have_key(:nav_sub_items)
    expect(hash[:nav_sub_items]).to include(after_sub_nav_item_name)

    index = hash[:nav_sub_items].find_index(after_sub_nav_item_name)
    hash[:nav_sub_items].insert(index, new_sub_nav_item_name)
  end

  def insert_package_nav
    insert_after_sub_nav_item(
      _("Feature flags"),
      within: _('Deploy'),
      new_sub_nav_item_name: _("Package Registry")
    )
  end

  def create_package_nav(before)
    insert_before_nav_item(
      before,
      new_nav_item: {
        nav_item: _("Deploy"),
        nav_sub_items: [_("Package Registry")]
      }
    )
  end

  def insert_customer_relations_nav(after)
    insert_after_sub_nav_item(
      after,
      within: _('Plan'),
      new_sub_nav_item_name: _("Customer relations")
    )
  end

  def insert_container_nav
    insert_after_sub_nav_item(
      _('Package Registry'),
      within: _('Deploy'),
      new_sub_nav_item_name: _('Container Registry')
    )
  end

  def insert_google_artifact_registry_nav
    insert_after_sub_nav_item(
      _('Container Registry'),
      within: _('Deploy'),
      new_sub_nav_item_name: _('Google Artifact Registry')
    )
  end

  def insert_dependency_proxy_nav
    insert_before_sub_nav_item(
      _('Kubernetes'),
      within: _('Operate'),
      new_sub_nav_item_name: _('Dependency Proxy')
    )
  end

  def insert_infrastructure_registry_nav(within)
    insert_after_sub_nav_item(
      within,
      within: _('Operate'),
      new_sub_nav_item_name: _('Terraform modules')
    )
  end

  def insert_harbor_registry_nav
    insert_after_sub_nav_item(
      _('Package Registry'),
      within: _('Deploy'),
      new_sub_nav_item_name: _('Harbor Registry')
    )
  end

  def insert_infrastructure_google_cloud_nav
    insert_after_sub_nav_item(
      s_('Terraform|Terraform modules'),
      within: _('Operate'),
      new_sub_nav_item_name: _('Google Cloud')
    )
  end

  def insert_infrastructure_aws_nav
    insert_after_sub_nav_item(
      _('Google Cloud'),
      within: _('Operate'),
      new_sub_nav_item_name: _('AWS')
    )
  end

  def insert_model_experiments_nav(within)
    insert_after_sub_nav_item(
      within,
      within: _('Analyze'),
      new_sub_nav_item_name: _('Model experiments')
    )
  end

  def insert_model_registry_nav(within)
    insert_after_sub_nav_item(
      within,
      within: _('Deploy'),
      new_sub_nav_item_name: _('Model registry')
    )
  end

  def insert_ai_agents_nav(within)
    insert_after_sub_nav_item(
      within,
      within: _('Deploy'),
      new_sub_nav_item_name: s_('AIAgents|AI Agents')
    )
  end

  def project_analytics_sub_nav_item
    [
      _('Value stream analytics'),
      _('Contributor analytics'),
      _('CI/CD analytics'),
      _('Repository analytics'),
      (_('Code review analytics') if Gitlab.ee?),
      (_('Merge request analytics') if Gitlab.ee?),
      _('Model experiments')
    ]
  end

  def group_analytics_sub_nav_item
    [_("Contribution analytics")]
  end
end

NavbarStructureHelper.prepend_mod
