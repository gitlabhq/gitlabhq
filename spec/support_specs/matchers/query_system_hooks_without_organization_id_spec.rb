# frozen_string_literal: true

require 'spec_helper'
require 'rspec/matchers/fail_matchers'

RSpec.describe 'query_system_hooks_without_organization_id matcher', feature_category: :webhooks do
  include RSpec::Matchers::FailMatchers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:hook) { create(:system_hook, organization: organization, push_events: true) }
  let_it_be(:other_organization_hook) { create(:system_hook, organization: other_organization) }

  let(:nothing_captured) { /no SELECT on `web_hooks` filtered on `type = 'SystemHook'` was captured/ }

  scoped_queries = {
    'a lookup through the organization' => -> { organization.system_hooks.find(hook.id) },
    'a presence check' => -> { SystemHook.for_organization(organization).hooks_for(:push_hooks).any? },
    'a count' => -> { organization.system_hooks.count },
    'an IN list' => -> { SystemHook.for_organization([organization, other_organization]).to_a },
    'a subquery' => -> {
      SystemHook.where(organization_id: Organizations::Organization.where(id: organization.id).select(:id)).to_a
    },
    'a join from organizations' => -> {
      Organizations::Organization.joins(:system_hooks).where(id: organization.id).to_a
    },
    'a union' => -> {
      SystemHook.from_union([SystemHook.for_organization(organization),
        SystemHook.for_organization(other_organization)])
        .to_a
    }
  }

  unscoped_queries = {
    'a lookup by ID' => -> { SystemHook.find(hook.id) },
    'a presence check' => -> { SystemHook.hooks_for(:push_hooks).any? },
    'a count' => -> { SystemHook.count },
    'a pluck of organization_id' => -> { SystemHook.pluck(:organization_id) },
    'an order by organization_id' => -> { SystemHook.order(:organization_id).to_a },
    'an IS NULL filter' => -> { SystemHook.where(organization_id: nil).to_a },
    'an IS NOT NULL filter' => -> { SystemHook.where.not(organization_id: nil).to_a },
    # rubocop:disable Rails/WhereEquals -- the unqualified raw SQL is what this case checks
    'an unqualified raw filter' => -> { SystemHook.where('organization_id = ?', organization.id).to_a },
    # rubocop:enable Rails/WhereEquals
    'a type IN list' => -> { WebHook.where(type: %w[SystemHook ProjectHook]).to_a }
  }

  queries_without_system_hook_filter = {
    'an empty block' => -> {},
    'a lookup through the base class' => -> { WebHook.find_by_id(hook.id) },
    'a project hook query' => -> { ProjectHook.all.to_a },
    'a hook log query' => -> { hook.web_hook_logs.to_a }
  }

  describe 'not_to' do
    scoped_queries.each do |description, query|
      it "passes for #{description}" do
        expect { instance_exec(&query) }.not_to query_system_hooks_without_organization_id
      end
    end

    unscoped_queries.each do |description, query|
      it "fails for #{description}" do
        expect { expect { instance_exec(&query) }.not_to query_system_hooks_without_organization_id }
          .to fail_with(/but 1 of 1 did not/)
      end
    end

    queries_without_system_hook_filter.each do |description, query|
      it "fails for #{description}, since no system hook query was captured" do
        expect { expect { instance_exec(&query) }.not_to query_system_hooks_without_organization_id }
          .to fail_with(nothing_captured)
      end
    end

    it 'ignores queries for other hook types' do
      expect do
        ProjectHook.all.to_a
        SystemHook.for_organization(organization).to_a
      end.not_to query_system_hooks_without_organization_id
    end

    it 'lists only the unscoped queries with their source' do
      expect do
        expect do
          SystemHook.for_organization(organization).to_a
          SystemHook.find(hook.id)
        end.not_to query_system_hooks_without_organization_id
      end.to fail_with(
        a_string_matching(/but 1 of 2 did not:\n\n.*#{Regexp.escape(File.basename(__FILE__))}:\d+:in /)
          .and(matching(/WHERE "web_hooks"\."type" = 'SystemHook' AND "web_hooks"\."id" = #{hook.id} LIMIT 1\z/))
      )
    end
  end

  describe 'to' do
    it 'is not supported' do
      expect { expect { SystemHook.find(hook.id) }.to query_system_hooks_without_organization_id }
        .to raise_error(ArgumentError, /only supports `not_to`/)
    end
  end

  describe SystemHookOrganizationScopeMatcher do
    let(:system_hook_select) { %(SELECT 1 FROM "web_hooks" WHERE "web_hooks"."type" = 'SystemHook') }

    def scoped?(sql)
      queries = described_class.system_hook_queries([sql])

      queries.any? && described_class.unscoped_queries(queries).none?
    end

    it 'treats bind parameters as an organization filter', :aggregate_failures do
      expect(scoped?(%(#{system_hook_select} AND "web_hooks"."organization_id" = $1))).to be(true)
      expect(scoped?(%(#{system_hook_select} AND "web_hooks"."organization_id" IN ($1, $2)))).to be(true)
    end

    it 'ignores an organization filter inside an annotation' do
      sql = %(#{system_hook_select} /*line:app/web_hooks/hook.rb:1:in '"web_hooks"."organization_id" = 1'*/)

      expect(scoped?(sql)).to be(false)
    end

    it 'checks unions and CTEs', :aggregate_failures do
      expect(described_class.system_hook_queries(["( (#{system_hook_select}) )"])).to be_present
      expect(described_class.system_hook_queries(["WITH x AS (#{system_hook_select}) SELECT 1"])).to be_present
    end

    it 'ignores statements other than SELECT' do
      sql = %(DELETE FROM "web_hooks" WHERE "web_hooks"."type" = 'SystemHook')

      expect(described_class.system_hook_queries([sql])).to be_empty
    end
  end
end
