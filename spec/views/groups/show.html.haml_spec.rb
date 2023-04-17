# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/show', feature_category: :subgroups do
  describe 'group README' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:readme_project) { build_stubbed(:project, :readme) }

    before do
      assign(:group, group)
    end

    context 'with readme project' do
      before do
        allow(group).to receive(:group_readme).and_return(readme_project)
      end

      it 'renders #js-group-readme' do
        render

        expect(rendered).to have_selector('#js-group-readme')
      end
    end

    context 'without readme project' do
      before do
        allow(group).to receive(:group_readme).and_return(nil)
      end

      it 'does not render #js-group-readme' do
        render

        expect(rendered).not_to have_selector('#js-group-readme')
      end
    end
  end
end
