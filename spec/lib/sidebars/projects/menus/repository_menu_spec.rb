# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::RepositoryMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master') }

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
      let(:ref) { 'master' }

      subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

      describe 'Commits' do
        let_it_be(:item_id) { :commits }

        context 'when there is a ref_type' do
          let(:context) do
            Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: ref,
                                            ref_type: ref_type)
          end

          let(:ref_type) { 'tags' }

          it 'has a links to commits with ref_type' do
            expect(subject.link).to eq("/#{project.full_path}/-/commits/#{ref}?ref_type=#{ref_type}")
          end
        end

        context 'when there is no ref_type' do
          let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: ref) }

          context 'and the use_ref_type_parameter is disabled' do
            before do
              stub_feature_flags(use_ref_type_parameter: false)
            end

            it 'has a links to commits' do
              expect(subject.link).to eq("/#{project.full_path}/-/commits/#{ref}")
            end
          end

          context 'and the use_ref_type_parameter flag is enabled' do
            it 'has a links to commits ref_type' do
              expect(subject.link).to eq("/#{project.full_path}/-/commits/#{ref}?ref_type=heads")
            end
          end
        end
      end

      describe 'Contributors' do
        let_it_be(:item_id) { :contributors }

        context 'when analytics is disabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)
          end

          it { is_expected.to be_nil }
        end

        context 'when analytics is enabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::ENABLED)
          end

          using RSpec::Parameterized::TableSyntax
          it { is_expected.not_to be_nil }

          shared_examples_for 'contributors menu link' do
            with_them do
              before do
                stub_feature_flags(use_ref_type_parameter: feature_flag_enabled)
              end

              it 'has a link to graphs with the fully qualifed ref route' do
                expect(subject.link).to eq(link)
              end
            end
          end

          describe 'link' do
            let(:context) do
              Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: ref,
                                              ref_type: ref_type)
            end

            it_behaves_like 'contributors menu link' do
              where(:feature_flag_enabled, :ref_type, :link) do
                true  | nil     | lazy { "/#{project.full_path}/-/graphs/#{ref}?ref_type=heads" }
                true  | 'heads' | lazy { "/#{project.full_path}/-/graphs/#{ref}?ref_type=heads" }
                true  | 'tags'  | lazy { "/#{project.full_path}/-/graphs/#{ref}?ref_type=tags" }
                false | nil     | lazy { "/#{project.full_path}/-/graphs/#{ref}" }
                false | 'heads' | lazy { "/#{project.full_path}/-/graphs/#{ref}" }
                false | 'tags'  | lazy { "/#{project.full_path}/-/graphs/#{ref}" }
              end
            end

            context 'when ref is not the default' do
              let(:ref) { 'nonmain' }

              it_behaves_like 'contributors menu link' do
                where(:feature_flag_enabled, :ref_type, :link) do
                  true  | nil     | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}" }
                  true  | 'heads' | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}?ref_type=heads" }
                  true  | 'tags'  | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}?ref_type=tags" }
                  false | nil     | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}" }
                  false | 'heads' | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}" }
                  false | 'tags'  | lazy { "/#{project.full_path}/-/graphs/#{context.current_ref}" }
                end
              end
            end
          end
        end
      end
    end
  end
end
