# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/notes/_form' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    assign(:project, project)
    assign(:note, note)

    allow(view).to receive(:current_user).and_return(user)

    render
  end

  %w[issue merge_request commit].each do |noteable|
    context "with a note on #{noteable}" do
      let(:note) { build(:"note_on_#{noteable}", project: project) }

      it 'says that markdown and quick actions are supported' do
        expect(rendered).to have_content('Markdown and quick actions are supported')
      end
    end
  end
end
