# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ApplicationContext do
  describe '.with_context' do
    it 'yields the block' do
      expect { |b| described_class.with_context({}, &b) }.to yield_control
    end

    it 'passes the expected context on to labkit' do
      user = build(:user)
      project = build(:project)
      fake_proc = duck_type(:call)
      expected_context = hash_including(user: fake_proc, project: fake_proc, root_namespace: fake_proc)

      expect(Labkit::Context).to receive(:with_context).with(expected_context)

      described_class.with_context(
        user: user,
        project: project,
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

  describe '.current_context_include?' do
    it 'returns true if the key was present in the context' do
      described_class.with_context(caller_id: "Hello") do
        expect(described_class.current_context_include?(:caller_id)).to be(true)
      end
    end

    it 'returns false if the key was not present in the current context' do
      expect(described_class.current_context_include?(:caller_id)).to be(false)
    end
  end

  describe '#to_lazy_hash' do
    let(:user) { build(:user) }
    let(:project) { build(:project) }
    let(:namespace) { create(:group) }
    let(:subgroup) { create(:group, parent: namespace) }

    def result(context)
      context.to_lazy_hash.transform_values { |v| v.respond_to?(:call) ? v.call : v }
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
  end

  describe '#use' do
    let(:context) { described_class.new(user: build(:user)) }

    it 'yields control' do
      expect { |b| context.use(&b) }.to yield_control
    end

    it 'passes the expected context on to labkit' do
      expect(Labkit::Context).to receive(:with_context).with(a_hash_including(user: duck_type(:call)))

      context.use {}
    end
  end
end
