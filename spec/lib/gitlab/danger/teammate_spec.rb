# frozen_string_literal: true

require 'fast_spec_helper'

require 'rspec-parameterized'

require 'gitlab/danger/teammate'

describe Gitlab::Danger::Teammate do
  subject { described_class.new(options.stringify_keys) }

  let(:options) { { username: 'luigi', projects: projects, role: role } }
  let(:projects) { { project => capabilities } }
  let(:role) { 'Engineer, Manage' }
  let(:labels) { [] }
  let(:project) { double }

  context 'when having multiple capabilities' do
    let(:capabilities) { ['reviewer backend', 'maintainer frontend', 'trainee_maintainer qa'] }

    it '#reviewer? supports multiple roles per project' do
      expect(subject.reviewer?(project, :backend, labels)).to be_truthy
    end

    it '#traintainer? supports multiple roles per project' do
      expect(subject.traintainer?(project, :qa, labels)).to be_truthy
    end

    it '#maintainer? supports multiple roles per project' do
      expect(subject.maintainer?(project, :frontend, labels)).to be_truthy
    end

    context 'when labels contain devops::create and the category is test' do
      let(:labels) { ['devops::create'] }

      context 'when role is Software Engineer in Test, Create' do
        let(:role) { 'Software Engineer in Test, Create' }

        it '#reviewer? returns true' do
          expect(subject.reviewer?(project, :test, labels)).to be_truthy
        end

        it '#maintainer? returns false' do
          expect(subject.maintainer?(project, :test, labels)).to be_falsey
        end

        context 'when hyperlink is mangled in the role' do
          let(:role) { '<a href="#">Software Engineer in Test</a>, Create' }

          it '#reviewer? returns true' do
            expect(subject.reviewer?(project, :test, labels)).to be_truthy
          end
        end
      end

      context 'when role is Software Engineer in Test' do
        let(:role) { 'Software Engineer in Test' }

        it '#reviewer? returns false' do
          expect(subject.reviewer?(project, :test, labels)).to be_falsey
        end
      end

      context 'when role is Software Engineer in Test, Manage' do
        let(:role) { 'Software Engineer in Test, Manage' }

        it '#reviewer? returns false' do
          expect(subject.reviewer?(project, :test, labels)).to be_falsey
        end
      end

      context 'when role is Backend Engineer, Engineering Productivity' do
        let(:role) { 'Backend Engineer, Engineering Productivity' }

        it '#reviewer? returns true' do
          expect(subject.reviewer?(project, :engineering_productivity, labels)).to be_truthy
        end

        it '#maintainer? returns false' do
          expect(subject.maintainer?(project, :engineering_productivity, labels)).to be_falsey
        end

        context 'when capabilities include maintainer backend' do
          let(:capabilities) { ['maintainer backend'] }

          it '#maintainer? returns true' do
            expect(subject.maintainer?(project, :engineering_productivity, labels)).to be_truthy
          end
        end

        context 'when capabilities include trainee_maintainer backend' do
          let(:capabilities) { ['trainee_maintainer backend'] }

          it '#traintainer? returns true' do
            expect(subject.traintainer?(project, :engineering_productivity, labels)).to be_truthy
          end
        end
      end
    end
  end

  context 'when having single capability' do
    let(:capabilities) { 'reviewer backend' }

    it '#reviewer? supports one role per project' do
      expect(subject.reviewer?(project, :backend, labels)).to be_truthy
    end

    it '#traintainer? supports one role per project' do
      expect(subject.traintainer?(project, :database, labels)).to be_falsey
    end

    it '#maintainer? supports one role per project' do
      expect(subject.maintainer?(project, :frontend, labels)).to be_falsey
    end
  end
end
