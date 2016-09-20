require 'spec_helper'

describe 'projects/notes/_form' do
  include Devise::TestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  before do
    project.team << [user, :master]
    assign(:project, project)
    assign(:note, note)

    allow(view).to receive(:current_user).and_return(user)

    render
  end

  %w[issue merge_request].each do |noteable|
    context "with a note on #{noteable}" do
      let(:note) { build(:"note_on_#{noteable}", project: project) }

      it 'says that only markdown is supported, not slash commands' do
        expect(rendered).to have_content('Styling with Markdown and slash commands are supported')
      end
    end
  end

  context 'with a note on a commit' do
    let(:note) { build(:note_on_commit, project: project) }

    it 'says that only markdown is supported, not slash commands' do
      expect(rendered).to have_content('Styling with Markdown is supported')
    end
  end
end
