# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy do
  describe 'ability :read_runner' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:owner) { create(:user) }

    let_it_be(:group1) { create(:group, name: 'top-level', path: 'top-level') }
    let_it_be(:subgroup1) { create(:group, name: 'subgroup1', path: 'subgroup1', parent: group1) }
    let_it_be(:project1) { create(:project, group: subgroup1) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group1_runner) { create(:ci_runner, :group, groups: [group1]) }
    let_it_be(:project1_runner) { create(:ci_runner, :project, projects: [project1]) }

    subject(:policy) { described_class.new(user, runner) }

    before do
      group1.add_guest(guest)
      group1.add_developer(developer)
      group1.add_owner(owner)
    end

    shared_context 'on hierarchy with shared runners disabled' do
      around do |example|
        group1.update!(shared_runners_enabled: false)
        project1.update!(shared_runners_enabled: false)

        example.run
      ensure
        project1.update!(shared_runners_enabled: true)
        group1.update!(shared_runners_enabled: true)
      end
    end

    shared_context 'on hierarchy with group runners disabled' do
      around do |example|
        project1.update!(group_runners_enabled: false)

        example.run
      ensure
        project1.update!(group_runners_enabled: true)
      end
    end

    shared_examples 'does not allow reading runners on any scope' do
      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_disallowed :read_runner }

        context 'with shared runners disabled' do
          include_context 'on hierarchy with shared runners disabled' do
            it { expect_disallowed :read_runner }
          end
        end
      end

      context 'with group runner' do
        let(:runner) { group1_runner }

        it { expect_disallowed :read_runner }

        context 'with group runner disabled' do
          include_context 'on hierarchy with group runners disabled' do
            it { expect_disallowed :read_runner }
          end
        end
      end

      context 'with project runner' do
        let(:runner) { project1_runner }

        it { expect_disallowed :read_runner }
      end
    end

    context 'without access' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with guest access' do
      let(:user) { guest }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with developer access' do
      let(:user) { developer }

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_allowed :read_runner }

        context 'with shared runners disabled' do
          include_context 'on hierarchy with shared runners disabled' do
            it { expect_disallowed :read_runner }
          end
        end
      end

      context 'with group runner' do
        let(:runner) { group1_runner }

        it { expect_allowed :read_runner }

        context 'with group runner disabled' do
          include_context 'on hierarchy with group runners disabled' do
            it { expect_disallowed :read_runner }
          end
        end
      end

      context 'with project runner' do
        let(:runner) { project1_runner }

        it { expect_disallowed :read_runner }
      end
    end

    context 'with owner access' do
      let(:user) { owner }

      context 'with instance runner' do
        let(:runner) { instance_runner }

        context 'with shared runners disabled' do
          include_context 'on hierarchy with shared runners disabled' do
            it { expect_disallowed :read_runner }
          end
        end

        it { expect_allowed :read_runner }
      end

      context 'with group runner' do
        let(:runner) { group1_runner }

        context 'with group runners disabled' do
          include_context 'on hierarchy with group runners disabled' do
            it { expect_allowed :read_runner }
          end
        end

        it { expect_allowed :read_runner }
      end

      context 'with project runner' do
        let(:runner) { project1_runner }

        it { expect_allowed :read_runner }
      end
    end
  end
end
