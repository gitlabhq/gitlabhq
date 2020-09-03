# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pipelines/new' do
  include Devise::Test::ControllerHelpers
  let_it_be(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  before do
    assign(:project, project)
    assign(:pipeline, pipeline)

    stub_feature_flags(new_pipeline_form: false)
  end

  describe 'warning messages' do
    let(:warning_messages) do
      [double(content: 'warning 1'), double(content: 'warning 2')]
    end

    before do
      allow(pipeline).to receive(:warning_messages).and_return(warning_messages)
    end

    it 'displays the warnings' do
      render

      expect(rendered).to have_css('div.bs-callout-warning')
      expect(rendered).to have_content('warning 1')
      expect(rendered).to have_content('warning 2')
    end
  end
end
