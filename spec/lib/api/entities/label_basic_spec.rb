# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::LabelBasic, feature_category: :team_planning do
  describe '#as_json' do
    subject { described_class.new(label, options).as_json }

    let(:options) { {} }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, group: group) }

    describe 'description_html' do
      let_it_be(:issue) { create(:issue, :confidential, project: project) }
      let_it_be(:user) { create(:user) }

      let(:label) { create(:label, project: project, description: "Label references #{issue.to_reference}") }
      let(:options) { { current_user: user } }
      let(:issue_path) { Gitlab::UrlBuilder.build(issue, only_path: true) }
      let(:issue_title) { issue.title }

      subject(:description_html) { described_class.new(label, options).as_json[:description_html] }

      it 'renders references if current user has access to the referent' do
        project.add_reporter(user)

        expect(description_html).to include(issue_path)
        expect(description_html).to include(issue_title)
      end

      it 'redacts references if current user has no access to the referent' do
        project.add_guest(user)

        expect(description_html).not_to include(issue_path)
        expect(description_html).not_to include(issue_title)
      end
    end

    describe '#archived' do
      let(:label) { create(:label, archived: true) }

      it { is_expected.to include(:archived) }
    end
  end
end
