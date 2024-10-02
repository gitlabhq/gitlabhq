# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPagesDomainAcmeOrdersProjectId,
  feature_category: :pages,
  schema: 20240930123728 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :pages_domain_acme_orders }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :pages_domains }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :pages_domain_id }
  end
end
