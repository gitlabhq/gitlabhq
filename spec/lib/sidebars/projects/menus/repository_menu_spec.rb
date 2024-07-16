# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::RepositoryMenu, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:is_super_sidebar) { false }
  let(:context) do
    Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master',
      is_super_sidebar: is_super_sidebar)
  end

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when project repository is empty' do
      it 'returns false' do
        allow(project).to receive(:empty_repo?).and_return(true)

        expect(subject.render?).to eq false
      end
    end

    context 'when project repository is not empty' do
      context 'when user can download code' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot download code' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end

    context 'for menu items' do
      shared_examples_for 'repository menu item link for' do
        let(:ref) { 'master' }
        subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id }.link }

        using RSpec::Parameterized::TableSyntax

        let(:context) do
          Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: ref,
            ref_type: ref_type)
        end

        where(:ref_type, :link) do
          nil     | lazy { "#{route}?ref_type=heads" }
          'heads' | lazy { "#{route}?ref_type=heads" }
          'tags'  | lazy { "#{route}?ref_type=tags" }
        end

        with_them do
          it 'has a link with the fully qualifed ref route' do
            expect(subject).to eq(link)
          end
        end

        context 'when ref is not the default' do
          let(:ref) { 'nonmain' }

          context 'and ref_type is not provided' do
            let(:ref_type) { nil }

            it { is_expected.to eq(route) }
          end

          context 'and ref_type is provided' do
            let(:ref_type) { 'heads' }

            it { is_expected.to eq("#{route}?ref_type=heads") }
          end
        end
      end

      shared_examples_for 'repository menu item with different super sidebar title' do |title, super_sidebar_title|
        subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

        specify do
          expect(subject.title).to eq(title)
        end

        context 'when inside the super sidebar' do
          let(:is_super_sidebar) { true }

          specify do
            expect(subject.title).to eq(super_sidebar_title)
          end
        end
      end

      describe 'Files' do
        let_it_be(:item_id) { :files }

        it_behaves_like 'repository menu item with different super sidebar title',
          _('Files'),
          _('Repository')
      end

      describe 'Commits' do
        let_it_be(:item_id) { :commits }

        it_behaves_like 'repository menu item link for' do
          let(:route) { "/#{project.full_path}/-/commits/#{ref}" }
        end
      end

      describe 'Contributor analytics' do
        let_it_be(:item_id) { :contributors }

        context 'when analytics is disabled' do
          subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)
          end

          it { is_expected.to be_nil }
        end

        context 'when analytics is enabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::ENABLED)
          end

          it_behaves_like 'repository menu item link for' do
            let(:route) { "/#{project.full_path}/-/graphs/#{ref}" }
          end
        end
      end

      describe 'Network' do
        let_it_be(:item_id) { :graphs }

        it_behaves_like 'repository menu item link for' do
          let(:route) { "/#{project.full_path}/-/network/#{ref}" }
        end

        it_behaves_like 'repository menu item with different super sidebar title',
          _('Graph'),
          _('Repository graph')
      end
    end
  end
end
