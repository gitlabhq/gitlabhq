# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrackingHelper do
  describe '#tracking_attrs' do
    using RSpec::Parameterized::TableSyntax

    let(:input) { %w(a b c) }
    let(:results) do
      {
        no_data: {},
        with_data: { data: { track_label: 'a', track_action: 'b', track_property: 'c' } }
      }
    end

    where(:snowplow_enabled, :environment, :result) do
      true  | 'production'  | :with_data
      false | 'production'  | :no_data
      true  | 'development' | :no_data
      false | 'development' | :no_data
      true  | 'test'        | :no_data
      false | 'test'        | :no_data
    end

    with_them do
      it 'returns a hash' do
        stub_application_setting(snowplow_enabled: snowplow_enabled)
        allow(Rails).to receive(:env).and_return(environment.inquiry)

        expect(helper.tracking_attrs(*input)).to eq(results[result])
      end
    end
  end
end
