# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../lib/api/helpers/custom_attributes_helpers'

RSpec.describe API::Helpers::CustomAttributesHelpers, feature_category: :groups_and_projects do
  let(:helper) do
    Class.new.include(described_class).new
  end

  before do
    allow(helper).to receive(:render_api_error!).and_raise('Invalid finder method')
    allow(helper).to receive(:not_found!).and_raise('404 Not found')
  end

  describe '#find_resource' do
    it 'returns what an allowed finder resolves' do
      project = Object.new
      allow(helper).to receive(:find_project).with(1).and_return(project)

      expect(helper.find_resource('find_project', 1)).to be(project)
    end

    it 'renders an error for a finder that is not allowed' do
      expect { helper.find_resource('find_note', 1) }.to raise_error('Invalid finder method')

      expect(helper).to have_received(:render_api_error!)
        .with('Invalid finder method: find_note', :bad_request)
    end

    it 'renders an error for an allowed finder the endpoint does not define' do
      expect { helper.find_resource('find_user', 1) }.to raise_error('Invalid finder method')
    end

    it 'renders 404 when the finder resolves nothing' do
      allow(helper).to receive(:find_group).with(1).and_return(nil)

      expect { helper.find_resource('find_group', 1) }.to raise_error('404 Not found')
    end
  end
end
