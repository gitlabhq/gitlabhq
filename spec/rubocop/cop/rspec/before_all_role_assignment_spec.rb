# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/rspec/before_all_role_assignment'

RSpec.describe Rubocop::Cop::RSpec::BeforeAllRoleAssignment, :rubocop_rspec, feature_category: :tooling do
  context 'with `let`' do
    context 'and `before_all`' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          context 'with something' do
            let(:project) { create(:project) }
            let(:guest)   { create(:user) }

            before_all do
              project.add_guest(guest)
            end
          end
        RUBY
      end
    end

    context 'and `before`' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          context 'with something' do
            let(:project) { create(:project) }
            let(:guest)   { create(:user) }

            before do
              project.add_guest(guest)
            end
          end
        RUBY
      end
    end
  end

  shared_examples '`let_it_be` definitions' do |let_it_be|
    context 'and `before_all`' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          context 'with something' do
            #{let_it_be}(:project) { create(:project) }
            #{let_it_be}(:guest)   { create(:user) }

            before_all do
              project.add_guest(guest)
            end
          end
        RUBY
      end
    end

    context 'and `before`' do
      context 'and without role methods' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            context 'with something' do
              #{let_it_be}(:project) { create(:project) }
              #{let_it_be}(:guest) { create(:user) }

              before do
                project.add_details(guest)
              end
            end
          RUBY
        end
      end

      context 'and role methods' do
        where(:role_method) { described_class::ROLE_METHODS.to_a }

        with_them do
          it 'registers an offense' do
            expect_offense(<<~RUBY, role_method: role_method)
              context 'with something' do
                #{let_it_be}(:project) { create(:project) }
                #{let_it_be}(:guest) { create(:user) }

                before do
                  project.%{role_method}(guest)
                  ^^^^^^^^^{role_method}^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                end
              end
            RUBY
          end
        end
      end

      context 'without nested contexts' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            context 'with something' do
              #{let_it_be}(:project) { create(:project) }
              #{let_it_be}(:guest) { create(:user) }

              before do
                project.add_guest(guest)
                ^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
              end
            end
          RUBY
        end
      end

      context 'with nested contexts' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            context 'when first context' do
              #{let_it_be}(:guest) { create(:user) }

              context 'when second context' do
                #{let_it_be}(:project) { create(:project) }

                context 'when third context' do
                  before do
                    project.add_guest(guest)
                    ^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                  end
                end
              end
            end
          RUBY
        end
      end

      describe 'edge cases' do
        context 'with unrelated `let_it_be` definition' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              context 'with something' do
                let(:project)    { create(:project) }
                #{let_it_be}(:user) { create(:user) }

                before do
                  project.add_guest(guest)
                end
              end
            RUBY
          end
        end

        context 'with many role method calls' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              context 'with something' do
                let(:project)             { create(:project) }
                #{let_it_be}(:other_project) { create(:user) }

                before do
                  project.add_guest(guest)
                  other_project.add_guest(guest)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                end
              end
            RUBY
          end
        end

        context 'with alternative example groups' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              describe 'with something' do
                #{let_it_be}(:project) { create(:user) }

                before do
                  project.add_guest(guest)
                  ^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                end
              end

              it_behaves_like 'with something' do
                #{let_it_be}(:project) { create(:user) }

                before do
                  project.add_guest(guest)
                  ^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                end
              end

              include_examples 'with something' do
                #{let_it_be}(:project) { create(:user) }

                before do
                  project.add_guest(guest)
                  ^^^^^^^^^^^^^^^^^^^^^^^^ Use `before_all` when used with `#{let_it_be}`.
                end
              end
            RUBY
          end
        end

        context 'with `let_it_be` outside of the ancestors chain' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              context 'when in main context' do
                let(:project) { create(:user) }

                before do
                  project.add_guest(guest)
                end

                context 'when in a separate context' do
                  #{let_it_be}(:project) { create(:user) }

                  before do
                    project
                  end
                end
              end
            RUBY
          end
        end
      end
    end
  end

  context 'with `let_it_be` variants' do
    before do
      other_cops.tap do |config|
        config.dig('RSpec', 'Language', 'Helpers')
          .push('let_it_be', 'let_it_be_with_reload', 'let_it_be_with_refind')
      end
    end

    where(:let_it_be) { %i[let_it_be let_it_be_with_reload let_it_be_with_refind] }

    with_them do
      include_examples '`let_it_be` definitions', params[:let_it_be]
    end
  end
end
