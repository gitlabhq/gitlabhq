# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InProductMarketingEmailCtaClickedMetric do
  using RSpec::Parameterized::TableSyntax

  let(:email_attributes) { { cta_clicked_at: Date.yesterday, track: 'verify', series: 0 } }
  let(:options) { { track: 'verify', series: 0 } }
  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT("in_product_marketing_emails"."id") FROM "in_product_marketing_emails"' \
    ' WHERE "in_product_marketing_emails"."cta_clicked_at" IS NOT NULL' \
    ' AND "in_product_marketing_emails"."series" = 0'\
    ' AND "in_product_marketing_emails"."track" = 1'
  end

  before do
    create_list :in_product_marketing_email, 2, email_attributes

    create :in_product_marketing_email, email_attributes.merge(cta_clicked_at: nil)
    create :in_product_marketing_email, email_attributes.merge(track: 'team')
    create :in_product_marketing_email, email_attributes.merge(series: 1)
  end

  it_behaves_like 'a correct instrumented metric value and query', {
    options: { track: 'verify', series: 0 },
    time_frame: 'all'
  }

  where(:options_key, :valid_value, :invalid_value) do
    :track        | 'admin_verify' | 'invite_team'
    :series       | 1              | 5
  end

  with_them do
    it "raises an exception if option is not present" do
      expect do
        described_class.new(options: options.except(options_key), time_frame: 'all')
      end.to raise_error(ArgumentError, %r{#{options_key} .* must be one of})
    end

    it "raises an exception if option has invalid value" do
      expect do
        options[options_key] = invalid_value
        described_class.new(options: options, time_frame: 'all')
      end.to raise_error(ArgumentError, %r{#{options_key} .* must be one of})
    end

    it "doesn't raise exceptions if option has valid value" do
      options[options_key] = valid_value
      described_class.new(options: options, time_frame: 'all')
    end
  end
end
