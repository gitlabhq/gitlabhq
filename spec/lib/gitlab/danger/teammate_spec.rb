# frozen_string_literal: true

require 'fast_spec_helper'

require 'gitlab/danger/teammate'

describe Gitlab::Danger::Teammate do
  subject { described_class.new(options) }
  let(:options) { { 'projects' => projects, 'role' => role } }
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

    context 'when labels contain Create and the category is test' do
      let(:labels) { ['devops::create'] }

      context 'when role is Test Automation Engineer, Create' do
        let(:role) { 'Test Automation Engineer, Create' }

        it '#reviewer? returns true' do
          expect(subject.reviewer?(project, :test, labels)).to be_truthy
        end

        it '#maintainer? returns false' do
          expect(subject.maintainer?(project, :test, labels)).to be_falsey
        end

        context 'when hyperlink is mangled in the role' do
          let(:role) { '<a href="#">Test Automation Engineer</a>, Create' }

          it '#reviewer? returns true' do
            expect(subject.reviewer?(project, :test, labels)).to be_truthy
          end
        end
      end

      context 'when role is Test Automation Engineer' do
        let(:role) { 'Test Automation Engineer' }

        it '#reviewer? returns false' do
          expect(subject.reviewer?(project, :test, labels)).to be_falsey
        end
      end

      context 'when role is Test Automation Engineer, Manage' do
        let(:role) { 'Test Automation Engineer, Manage' }

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
