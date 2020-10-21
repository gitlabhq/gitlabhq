# frozen_string_literal: true

require 'timecop'
require 'rspec-parameterized'

require 'gitlab/danger/teammate'
require 'active_support/testing/time_helpers'

RSpec.describe Gitlab::Danger::Teammate do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(options) }

  let(:tz_offset_hours) { 2.0 }
  let(:options) do
    {
      'username' => 'luigi',
      'projects' => projects,
      'role' => role,
      'markdown_name' => '[Luigi](https://gitlab.com/luigi) (`@luigi`)',
      'tz_offset_hours' => tz_offset_hours
    }
  end

  let(:capabilities) { ['reviewer backend'] }
  let(:projects) { { project => capabilities } }
  let(:role) { 'Engineer, Manage' }
  let(:labels) { [] }
  let(:project) { double }

  describe '#==' do
    it 'compares Teammate username' do
      joe1 = described_class.new('username' => 'joe', 'projects' => projects)
      joe2 = described_class.new('username' => 'joe', 'projects' => [])
      jane1 = described_class.new('username' => 'jane', 'projects' => projects)
      jane2 = described_class.new('username' => 'jane', 'projects' => [])

      expect(joe1).to eq(joe2)
      expect(jane1).to eq(jane2)
      expect(jane1).not_to eq(nil)
      expect(described_class.new('username' => nil)).not_to eq(nil)
    end
  end

  describe '#to_h' do
    it 'returns the given options' do
      expect(subject.to_h).to eq(options)
    end
  end

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

  describe '#local_hour' do
    include ActiveSupport::Testing::TimeHelpers

    around do |example|
      travel_to(Time.utc(2020, 6, 23, 10)) { example.run }
    end

    context 'when author is given' do
      where(:tz_offset_hours, :expected_local_hour) do
        -12 | 22
        -10 | 0
        2 | 12
        4 | 14
        12 | 22
      end

      with_them do
        it 'returns the correct local_hour' do
          expect(subject.local_hour).to eq(expected_local_hour)
        end
      end
    end
  end

  describe '#markdown_name' do
    it 'returns markdown name with timezone info' do
      expect(subject.markdown_name).to eq("#{options['markdown_name']} (UTC+2)")
    end

    context 'when offset is 1.5' do
      let(:tz_offset_hours) { 1.5 }

      it 'returns markdown name with timezone info, not truncated' do
        expect(subject.markdown_name).to eq("#{options['markdown_name']} (UTC+1.5)")
      end
    end

    context 'when author is given' do
      where(:tz_offset_hours, :author_offset, :diff_text) do
        -12 | -10 | "2 hours behind `@mario`"
        -10 | -12 | "2 hours ahead of `@mario`"
        -10 | 2 | "12 hours behind `@mario`"
        2 | 4 | "2 hours behind `@mario`"
        4 | 2 | "2 hours ahead of `@mario`"
        2 | 3 | "1 hour behind `@mario`"
        3 | 2 | "1 hour ahead of `@mario`"
        2 | 2 | "same timezone as `@mario`"
      end

      with_them do
        it 'returns markdown name with timezone info' do
          author = described_class.new(options.merge('username' => 'mario', 'tz_offset_hours' => author_offset))

          floored_offset_hours = subject.__send__(:floored_offset_hours)
          utc_offset = floored_offset_hours >= 0 ? "+#{floored_offset_hours}" : floored_offset_hours

          expect(subject.markdown_name(author: author)).to eq("#{options['markdown_name']} (UTC#{utc_offset}, #{diff_text})")
        end
      end
    end
  end
end
