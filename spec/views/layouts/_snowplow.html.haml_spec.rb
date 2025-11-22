# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_snowplow', feature_category: :service_ping do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }
  let(:project) { build_stubbed(:project, namespace: group) }

  before do
    allow(view).to receive(:current_application_settings)
      .and_return(Gitlab::CurrentSettings.current_application_settings)
    assign(:project, project)
    assign(:group, group)
  end

  context 'when user is authenticated' do
    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'includes sensitive fields in the context' do
      render

      expect(rendered).to include('instance_version')
      expect(rendered).to include('instance_id')
      expect(rendered).to include('host_name')
      expect(rendered).to include('plan')
    end
  end

  context 'when user is not authenticated' do
    before do
      allow(view).to receive(:current_user).and_return(nil)
    end

    it 'filters sensitive fields from the context' do
      render

      expect(rendered).not_to include('instance_version')
      expect(rendered).not_to include('instance_id')
      expect(rendered).not_to include('host_name')
      expect(rendered).not_to include('plan')
    end

    it 'includes non-sensitive fields in the context' do
      render

      expect(rendered).to include('environment')
      expect(rendered).to include('source')
      expect(rendered).to include('correlation_id')
    end
  end
end
