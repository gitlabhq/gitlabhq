# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }

  let(:policy) do
    described_class.new(user, environment)
  end

  describe '#rules' do
    shared_examples 'project permissions' do
      context 'with stop action' do
        let(:environment) do
          create(:environment, :with_review_app, project: project)
        end

        where(:access_level, :allowed?) do
          nil         | false
          :guest      | false
          :reporter   | false
          :developer  | true
          :maintainer | true
        end

        with_them do
          before do
            project.add_user(user, access_level) unless access_level.nil?
          end

          it { expect(policy.allowed?(:stop_environment)).to be allowed? }
        end

        context 'when an admin user' do
          let(:user) { create(:user, :admin) }

          it { expect(policy).to be_allowed :stop_environment }
        end

        context 'with protected branch' do
          with_them do
            before do
              project.add_user(user, access_level) unless access_level.nil?
              create(:protected_branch, :no_one_can_push,
                     name: 'master', project: project)
            end

            it { expect(policy).to be_disallowed :stop_environment }
          end

          context 'when an admin user' do
            let(:user) { create(:user, :admin) }

            it { expect(policy).to be_allowed :stop_environment }
          end
        end
      end

      context 'without stop action' do
        let(:environment) do
          create(:environment, project: project)
        end

        where(:access_level, :allowed?) do
          nil         | false
          :guest      | false
          :reporter   | false
          :developer  | true
          :maintainer | true
        end

        with_them do
          before do
            project.add_user(user, access_level) unless access_level.nil?
          end

          it { expect(policy.allowed?(:stop_environment)).to be allowed? }
        end

        context 'when an admin user' do
          let(:user) { create(:user, :admin) }

          it { expect(policy).to be_allowed :stop_environment }
        end
      end
    end

    context 'when project is public' do
      let(:project) { create(:project, :public, :repository) }

      include_examples 'project permissions'
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, :repository) }

      include_examples 'project permissions'
    end
  end
end
