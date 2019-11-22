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

  describe '#status' do
    let(:capabilities) { ['dish washing'] }

    context 'with empty cache' do
      context 'for successful request' do
        it 'returns the response' do
          mock_status = double(does_not: 'matter')
          expect(Gitlab::Danger::RequestHelper).to receive(:http_get_json)
                                                       .and_return(mock_status)

          expect(subject.status).to be mock_status
        end
      end

      context 'for failing request' do
        it 'returns nil' do
          expect(Gitlab::Danger::RequestHelper).to receive(:http_get_json)
                                                       .and_raise(Gitlab::Danger::RequestHelper::HTTPError.new)

          expect(subject.status).to be nil
        end
      end
    end

    context 'with filled cache' do
      it 'returns the cached response' do
        mock_status = double(does_not: 'matter')
        expect(Gitlab::Danger::RequestHelper).to receive(:http_get_json)
                                                     .and_return(mock_status)
        subject.status

        expect(Gitlab::Danger::RequestHelper).not_to receive(:http_get_json)
        expect(subject.status).to be mock_status
      end
    end
  end

  describe '#available?' do
    using RSpec::Parameterized::TableSyntax

    let(:capabilities) { ['dry head'] }

    where(:status, :result) do
      {}                               | true
      { message: 'dear reader' }       | true
      { message: 'OOO: massage' }      | false
      { message: 'love it SOOO much' } | false
      { emoji: 'red_circle' }          | false
    end

    with_them do
      before do
        expect(Gitlab::Danger::RequestHelper).to receive(:http_get_json)
                                                     .and_return(status&.stringify_keys)
      end

      it { expect(subject.available?).to be result }
    end

    it 'returns true if request fails' do
      expect(Gitlab::Danger::RequestHelper).to receive(:http_get_json)
                                                   .exactly(2).times
                                                   .and_raise(Gitlab::Danger::RequestHelper::HTTPError.new)

      expect(subject.available?).to be true
    end
  end
end
