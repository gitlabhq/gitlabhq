# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ApplicationContext do
  describe '.with_context' do
    it 'yields the block' do
      expect { |b| described_class.with_context({}, &b) }.to yield_control
    end

    it 'passes the expected context on to labkit' do
      fake_proc = duck_type(:call)
      expected_context = hash_including(user: fake_proc, project: fake_proc, root_namespace: fake_proc)

      expect(Labkit::Context).to receive(:with_context).with(expected_context)

      described_class.with_context(
        user: build(:user),
        project: build(:project),
        namespace: build(:namespace)) {}
    end

    it 'raises an error when passing invalid options' do
      expect { described_class.with_context(no: 'option') {} }.to raise_error(ArgumentError)
    end
  end

  describe '.push' do
    it 'passes the expected context on to labkit' do
      fake_proc = duck_type(:call)
      expected_context = { user: fake_proc }

      expect(Labkit::Context).to receive(:push).with(expected_context)

      described_class.push(user: build(:user))
    end

    it 'raises an error when passing invalid options' do
      expect { described_class.push(no: 'option')}.to raise_error(ArgumentError)
    end
  end

  describe '#to_lazy_hash' do
    let(:user) { build(:user) }
    let(:project) { build(:project) }
    let(:namespace) { build(:group) }
    let(:subgroup) { build(:group, parent: namespace) }

    def result(context)
      context.to_lazy_hash.transform_values { |v| v.call }
    end

    it 'does not call the attributes until needed' do
      fake_proc = double('Proc')

      expect(fake_proc).not_to receive(:call)

      described_class.new(user: fake_proc, project: fake_proc, namespace: fake_proc).to_lazy_hash
    end

    it 'correctly loads the expected values when they are wrapped in a block' do
      context = described_class.new(user: -> { user }, project: -> { project }, namespace: -> { subgroup })

      expect(result(context))
        .to include(user: user.username, project: project.full_path, root_namespace: namespace.full_path)
    end

    it 'correctly loads the expected values when passed directly' do
      context = described_class.new(user: user, project: project, namespace: subgroup)

      expect(result(context))
        .to include(user: user.username, project: project.full_path, root_namespace: namespace.full_path)
    end

    it 'falls back to a projects namespace when a project is passed but no namespace' do
      context = described_class.new(project: project)

      expect(result(context))
        .to include(project: project.full_path, root_namespace: project.full_path_components.first)
    end

    context 'only include values for which an option was specified' do
      using RSpec::Parameterized::TableSyntax

      where(:provided_options, :expected_context_keys) do
        [:user, :namespace, :project] | [:user, :project, :root_namespace]
        [:user, :project]             | [:user, :project, :root_namespace]
        [:user, :namespace]           | [:user, :root_namespace]
        [:user]                       | [:user]
        []                            | []
      end

      with_them do
        it do
          # Build a hash that has all `provided_options` as keys, and `nil` as value
          provided_values = provided_options.map { |key| [key, nil] }.to_h
          context = described_class.new(provided_values)

          expect(context.to_lazy_hash.keys).to contain_exactly(*expected_context_keys)
        end
      end
    end
  end
end
