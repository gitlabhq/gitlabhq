# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::FeatureLibrary::Catalog, feature_category: :onboarding do
  def nav_item(**attributes)
    Onboarding::FeatureLibrary::Catalog::NavItem.new(
      item_id: :audit_events, panel: :group, category: :secure_menu, tier: :premium,
      licensed_features: [:audit_events], title: 'Audit events', description: 'Track changes',
      icon: 'audit-events', docs_path: 'user/compliance/audit_events.md', **attributes
    )
  end

  def capability(**attributes)
    Onboarding::FeatureLibrary::Catalog::Capability.new(
      id: :merge_controls, panel: :group, tier: :premium, title: 'Merge controls',
      description: 'Require approvals', icon: 'code', docs_path: 'ci/pipelines/merge_trains.md', **attributes
    )
  end

  def enhancement(item, tier, text)
    Onboarding::FeatureLibrary::Catalog::Enhancement.new(nav_item: item, tier: tier, text: text)
  end

  # Heading anchors as the docs site generates them: lowercased, punctuation removed, spaces to hyphens.
  def markdown_anchors(file)
    file.read.scan(/^\#{1,6}\s+(.+?)\s*#*$/).flatten.map do |heading|
      heading.downcase.gsub(/[^\p{Word}\- ]/, '').tr(' ', '-')
    end
  end

  # Validates the real content, so a new or edited entry can't ship malformed. Runs in
  # CE too, so a catalog that references EE-only code fails in as-if-FOSS pipelines.
  describe 'catalog content' do
    let(:nav_items) { described_class.nav_items }
    let(:capabilities) { described_class.capabilities }
    let(:nav_item_tiers) { %i[free premium ultimate add_on] }
    let(:capability_tiers) { %i[premium ultimate add_on] }

    it 'has unique nav item keys per panel' do
      keys = nav_items.map { |item| [item.panel, item.item_id] }

      expect(keys).to eq(keys.uniq)
    end

    it 'has unique capability keys per panel that do not reuse nav item ids' do
      keys = capabilities.map { |capability| [capability.panel, capability.id] }
      nav_keys = nav_items.map { |item| [item.panel, item.item_id] }

      expect(keys).to eq(keys.uniq)
      expect(keys & nav_keys).to be_empty
    end

    it 'uses known panels, categories, tiers and deployments', :aggregate_failures do
      nav_items.each do |item|
        expect(described_class::PANELS).to include(item.panel), "#{item.item_id}: unknown panel"
        expect(described_class::CATEGORIES).to have_key(item.category), "#{item.item_id}: unknown category"
        expect(nav_item_tiers).to include(item.tier), "#{item.item_id}: unknown tier"
        expect(item.shown_on_deployments).to be_present.and(all(be_in(described_class::DEPLOYMENTS)))
      end

      capabilities.each do |capability|
        expect(described_class::PANELS).to include(capability.panel), "#{capability.id}: unknown panel"
        expect(capability_tiers).to include(capability.tier), "#{capability.id}: unknown tier"
        expect(capability.shown_on_deployments).to be_present.and(all(be_in(described_class::DEPLOYMENTS)))
      end
    end

    # Paid items are listed as new items, so enhancements on them would list them twice on a page.
    it 'gives paid nav items licensed features and only free nav items enhancements', :aggregate_failures do
      nav_items.each do |item|
        if item.tier == :free
          expect(item.enhancements).to be_present, "#{item.item_id}: free items are only listed for enhancements"
        else
          expect(item.enhancements).to be_empty, "#{item.item_id}: paid items can't have enhancements"
          next if item.tier == :add_on

          expect(item.licensed_features).to be_present, "#{item.item_id}: needs licensed features"
        end

        expect(item.enhancements.keys).to all(be_in(described_class::TIER_PAGES))
        expect(item.enhancements.values).to all(be_present)
      end
    end

    it 'has a title, description and icon on every entry', :aggregate_failures do
      (nav_items + capabilities).each do |entry|
        expect([entry.title, entry.description, entry.icon]).to all(be_present), "#{entry.inspect} is incomplete"
      end
    end

    it 'points every entry at an existing docs page and anchor', :aggregate_failures do
      (nav_items + capabilities).map(&:docs_path).uniq.each do |docs_path|
        path, anchor = docs_path.split('#', 2)
        file = Rails.root.join('doc', path)

        expect(file).to exist, "#{docs_path}: no such docs page"
        expect(markdown_anchors(file)).to include(anchor), "#{docs_path}: no such anchor" if anchor && file.exist?
      end
    end

    # A highlight only appears on its own tier's page, so pages can only limit add-on cards.
    it 'limits add-on capabilities to known pages and leaves highlights on the default', :aggregate_failures do
      every_page = described_class::DEPLOYMENTS.index_with { described_class::TIER_PAGES }

      capabilities.each do |capability|
        if capability.tier == :add_on
          expect(capability.pages.keys).to match_array(described_class::DEPLOYMENTS), "#{capability.id}: deployments"
          expect(capability.pages.values).to all(be_present.and(all(be_in(described_class::TIER_PAGES)))),
            "#{capability.id}: unknown page"
        else
          expect(capability.pages).to eq(every_page), "#{capability.id}: pages has no effect on a highlight"
        end
      end
    end

    it 'declares every placeholder its description uses, from the supported set', :aggregate_failures do
      capabilities.each do |capability|
        placeholders = capability.description.scan(/%\{(\w+)\}/).flatten.map(&:to_sym)

        expect(capability.description_variables).to match_array(placeholders), "#{capability.id}: placeholders drifted"
        expect(capability.description_variables).to all(be_in(described_class::DESCRIPTION_VARIABLES)),
          "#{capability.id}: unsupported placeholder"
      end
    end

    it 'lists a compute minutes capability per page on each panel, on GitLab.com only', :aggregate_failures do
      compute = capabilities.select { |capability| capability.id.to_s.start_with?('compute_minutes') }

      expect(compute.map { |capability| [capability.panel, capability.id] }).to contain_exactly(
        [:group, :compute_minutes_premium], [:group, :compute_minutes_ultimate],
        [:project, :compute_minutes_premium], [:project, :compute_minutes_ultimate]
      )
      expect(compute.map(&:shown_on_deployments)).to all(eq([:saas]))
      expect(compute.map(&:tier)).to all(be_in(described_class::TIER_PAGES))
    end

    it 'only supersedes nav items in the same panel' do
      unknown = capabilities.flat_map do |capability|
        capability.supersedes_nav_items.reject { |item_id| described_class.find_nav_item(capability.panel, item_id) }
      end

      expect(unknown).to be_empty
    end
  end

  describe described_class::NavItem do
    it 'defaults optional attributes', :aggregate_failures do
      item = nav_item

      expect(item.shown_on_deployments).to eq(Onboarding::FeatureLibrary::Catalog::DEPLOYMENTS)
      expect(item.enhancements).to eq({})
    end

    it 'translates the title and description', :aggregate_failures do
      expect(nav_item.translated_title).to eq('Audit events')
      expect(nav_item.translated_description).to eq('Track changes')
    end

    describe '#enhancement_for' do
      it 'returns the page own text and tier', :aggregate_failures do
        item = nav_item(enhancements: { premium: 'Scoped labels', ultimate: 'Custom fields' })

        expect(item.enhancement_for(:premium)).to eq(enhancement(item, :premium, 'Scoped labels'))
        expect(item.enhancement_for(:ultimate)).to eq(enhancement(item, :ultimate, 'Custom fields'))
      end

      it 'inherits the Premium text on the cumulative Ultimate page, tagged as Premium' do
        item = nav_item(enhancements: { premium: 'Scoped labels' })

        expect(item.enhancement_for(:ultimate)).to eq(enhancement(item, :premium, 'Scoped labels'))
      end

      it 'does not use the Ultimate text on the Premium page' do
        expect(nav_item(enhancements: { ultimate: 'Custom fields' }).enhancement_for(:premium)).to be_nil
      end
    end
  end

  describe described_class::Capability do
    it 'defaults optional attributes', :aggregate_failures do
      expect(capability.shown_on_deployments).to eq(Onboarding::FeatureLibrary::Catalog::DEPLOYMENTS)
      expect(capability.pages).to eq(saas: %i[premium ultimate], self_managed: %i[premium ultimate])
      expect(capability.supersedes_nav_items).to eq([])
    end

    describe '#pages_on' do
      it 'applies an Array to every deployment', :aggregate_failures do
        limited = capability(pages: [:premium])

        expect(limited.pages_on(:saas)).to eq([:premium])
        expect(limited.pages_on(:self_managed)).to eq([:premium])
      end

      it 'applies a Hash per deployment, defaulting the rest to every page', :aggregate_failures do
        limited = capability(pages: { self_managed: [:premium] })

        expect(limited.pages_on(:saas)).to eq(%i[premium ultimate])
        expect(limited.pages_on(:self_managed)).to eq([:premium])
      end
    end

    it 'translates the title and description', :aggregate_failures do
      expect(capability.translated_title).to eq('Merge controls')
      expect(capability.translated_description).to eq('Require approvals')
    end

    describe '#translated_description with variables' do
      let(:compute) do
        capability(description: 'Get %{plan_minutes} minutes on %{base_plan}',
          description_variables: %i[plan_minutes base_plan])
      end

      it 'fills the declared placeholders and ignores extra variables' do
        expect(compute.translated_description(plan_minutes: '10,000', base_plan: 'Free', unused: 1))
          .to eq('Get 10,000 minutes on Free')
      end

      it 'names the missing variables' do
        expect { compute.translated_description(plan_minutes: '10,000') }
          .to raise_error(ArgumentError, 'merge_controls description needs base_plan')
      end

      it 'ignores variables when the description declares none' do
        expect(capability.translated_description(plan_minutes: '10,000')).to eq('Require approvals')
      end
    end
  end

  describe '.find_nav_item' do
    let(:other_panel) { :project }
    let(:group_item) { nav_item }
    let(:other_panel_item) { nav_item(panel: other_panel) }

    before do
      allow(described_class).to receive(:nav_items).and_return([group_item, other_panel_item])
    end

    it 'finds the nav item by panel and id', :aggregate_failures do
      expect(described_class.find_nav_item(:group, :audit_events)).to eq(group_item)
      expect(described_class.find_nav_item(other_panel, :audit_events)).to eq(other_panel_item)
      expect(described_class.find_nav_item(:group, :unknown)).to be_nil
    end
  end

  describe '.explore_pages' do
    let(:other_panel) { :project }

    let(:premium_item) { nav_item }
    let(:ultimate_item) { nav_item(item_id: :security_dashboard, tier: :ultimate) }
    let(:add_on_item) { nav_item(item_id: :ai_agents, category: :duo_agents_menu, tier: :add_on) }
    let(:saas_only_item) { nav_item(item_id: :credentials, tier: :ultimate, shown_on_deployments: [:saas]) }
    let(:other_panel_item) { nav_item(panel: other_panel) }
    let(:enhanced_item) do
      nav_item(item_id: :labels, category: :manage_menu, tier: :free, licensed_features: [],
        enhancements: { premium: 'Scoped labels' })
    end

    let(:superseded_item) do
      nav_item(item_id: :group_merge_request_list, category: :code_menu, tier: :free, licensed_features: [],
        enhancements: { premium: 'Approvals' })
    end

    let(:premium_highlight) { capability(supersedes_nav_items: [:group_merge_request_list]) }
    let(:ultimate_highlight) { capability(id: :advanced_sast, tier: :ultimate) }
    let(:credits) { capability(id: :duo_agent_platform, tier: :add_on, supersedes_nav_items: [:ai_agents]) }
    let(:premium_only_credits) do
      capability(id: :secrets_manager, tier: :add_on, pages: { self_managed: [:premium] })
    end

    subject(:pages) { described_class.explore_pages(panel: :group, deployment: :self_managed) }

    before do
      allow(described_class).to receive_messages(
        nav_items: [premium_item, ultimate_item, add_on_item, saas_only_item, other_panel_item, enhanced_item,
          superseded_item],
        capabilities: [premium_highlight, ultimate_highlight, credits, premium_only_credits]
      )
    end

    it 'returns an Explore page for both tiers', :aggregate_failures do
      expect(pages.keys).to eq(%i[premium ultimate])
      expect(pages.values).to all(be_a(Onboarding::FeatureLibrary::Catalog::ExplorePage))
    end

    it 'lists only the page own highlights, and credits on the pages they allow', :aggregate_failures do
      expect(pages[:premium].highlights).to contain_exactly(premium_highlight)
      expect(pages[:ultimate].highlights).to contain_exactly(ultimate_highlight)
      expect(pages[:premium].credits).to contain_exactly(credits, premium_only_credits)
      expect(pages[:ultimate].credits).to contain_exactly(credits)
      expect(described_class.explore_pages(panel: :group, deployment: :saas)[:ultimate].credits)
        .to contain_exactly(credits, premium_only_credits)
    end

    it 'makes the Ultimate page cumulative', :aggregate_failures do
      expect(pages[:premium].new_items).to contain_exactly(premium_item)
      expect(pages[:ultimate].new_items).to contain_exactly(premium_item, ultimate_item)
    end

    it 'drops nav items a capability supersedes', :aggregate_failures do
      expect(pages[:premium].new_items).not_to include(add_on_item)
      expect(pages[:premium].enhanced_items.map(&:nav_item)).not_to include(superseded_item)
    end

    it 'lists enhancements tagged with the tier their text describes' do
      expect(pages[:premium].enhanced_items).to contain_exactly(enhancement(enhanced_item, :premium, 'Scoped labels'))
    end

    # Premium highlights are not shown there, so the nav items they supersede come back.
    it 'inherits Premium enhancements on the Ultimate page' do
      expect(pages[:ultimate].enhanced_items).to contain_exactly(
        enhancement(enhanced_item, :premium, 'Scoped labels'),
        enhancement(superseded_item, :premium, 'Approvals')
      )
    end

    it 'filters by deployment and panel', :aggregate_failures do
      all_items = pages.values.flat_map(&:new_items)

      expect(all_items).not_to include(saas_only_item, other_panel_item)
      expect(described_class.explore_pages(panel: :group, deployment: :saas)[:ultimate].new_items)
        .to include(saas_only_item)
    end
  end
end
