# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomTemplates, feature_category: :service_desk do
  describe '#enabled?' do
    subject(:enabled) { described_class.new(project).enabled? }

    # The restriction is GitLab.com only, so the CE implementation always
    # allows custom templates. See the EE spec for the restriction matrix.
    context 'with a free root namespace created after the cutoff' do
      let(:project) do
        group = create(:group, created_at: described_class::RESTRICTED_FROM_DATE + 1.day)
        create(:project, group: group)
      end

      it { is_expected.to be(true) }
    end

    context 'with a personal namespace created after the cutoff' do
      let(:project) do
        create(:project, namespace: create(:user_namespace,
          created_at: described_class::RESTRICTED_FROM_DATE + 1.day))
      end

      it { is_expected.to be(true) }
    end
  end
end
