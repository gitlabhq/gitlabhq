# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter do
  let(:project_id) { 1 }

  describe '.track_unique_project_event' do
    described_class::TEMPLATE_TO_EVENT.keys.each do |template|
      context "when given template #{template}" do
        it_behaves_like 'tracking unique hll events', :usage_data_track_ci_templates_unique_projects do
          subject(:request) { described_class.track_unique_project_event(project_id: project_id, template: template) }

          let(:target_id) { "p_ci_templates_#{described_class::TEMPLATE_TO_EVENT[template]}" }
          let(:expected_type) { instance_of(Integer) }
        end
      end
    end

    it 'does not track templates outside of TEMPLATE_TO_EVENT' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to(
        receive(:track_event)
      )
      Dir.glob(File.join('lib', 'gitlab', 'ci', 'templates', '**'), base: Rails.root) do |template|
        next if described_class::TEMPLATE_TO_EVENT.key?(template)

        described_class.track_unique_project_event(project_id: 1, template: template)
      end
    end
  end
end
