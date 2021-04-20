# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PagesTransfer do
  describe '#async' do
    let(:async) { subject.async }

    context 'when receiving an allowed method' do
      it 'schedules a PagesTransferWorker', :aggregate_failures do
        described_class::METHODS.each do |meth|
          expect(PagesTransferWorker)
            .to receive(:perform_async).with(meth, %w[foo bar])

          async.public_send(meth, 'foo', 'bar')
        end
      end

      it 'does nothing if legacy storage is disabled' do
        allow(Settings.pages.local_store).to receive(:enabled).and_return(false)

        described_class::METHODS.each do |meth|
          expect(PagesTransferWorker)
            .not_to receive(:perform_async)

          async.public_send(meth, 'foo', 'bar')
        end
      end
    end

    context 'when receiving a private method' do
      it 'raises NoMethodError' do
        expect { async.move('foo', 'bar') }.to raise_error(NoMethodError)
      end
    end

    context 'when receiving a non-existent method' do
      it 'raises NoMethodError' do
        expect { async.foo('bar') }.to raise_error(NoMethodError)
      end
    end
  end

  RSpec.shared_examples 'moving a pages directory' do |parameter|
    let!(:pages_path_before) { project.pages_path }
    let(:config_path_before) { File.join(pages_path_before, 'config.json') }
    let(:pages_path_after) { project.reload.pages_path }
    let(:config_path_after) { File.join(pages_path_after, 'config.json') }

    before do
      FileUtils.mkdir_p(pages_path_before)
      FileUtils.touch(config_path_before)
    end

    after do
      FileUtils.remove_entry(pages_path_before, true)
      FileUtils.remove_entry(pages_path_after, true)
    end

    it 'moves the directory' do
      subject.public_send(meth, *args)

      expect(File.exist?(config_path_before)).to be(false)
      expect(File.exist?(config_path_after)).to be(true)
    end

    it 'returns false if it fails to move the directory' do
      # Move the directory once, so it can't be moved again
      subject.public_send(meth, *args)

      expect(subject.public_send(meth, *args)).to be(false)
    end

    it 'does nothing if legacy storage is disabled' do
      allow(Settings.pages.local_store).to receive(:enabled).and_return(false)

      subject.public_send(meth, *args)

      expect(File.exist?(config_path_before)).to be(true)
      expect(File.exist?(config_path_after)).to be(false)
    end
  end

  describe '#move_namespace' do
    # Can't use let_it_be because we change the path
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:subgroup) { create(:group, parent: group_1) }
    let(:project) { create(:project, group: subgroup) }
    let(:new_path) { "#{group_2.path}/#{subgroup.path}" }
    let(:meth) { 'move_namespace' }

    # Store the path before we change it
    let!(:args) { [project.path, subgroup.full_path, new_path] }

    before do
      # We need to skip hooks, otherwise the directory will be moved
      # via an ActiveRecord callback
      subgroup.update_columns(parent_id: group_2.id)
      subgroup.route.update!(path: new_path)
    end

    include_examples 'moving a pages directory'
  end

  describe '#move_project' do
    # Can't use let_it_be because we change the path
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:project) { create(:project, group: group_1) }
    let(:new_path) { group_2.path }
    let(:meth) { 'move_project' }
    let(:args) { [project.path, group_1.full_path, group_2.full_path] }

    include_examples 'moving a pages directory' do
      before do
        project.update!(group: group_2)
      end
    end
  end

  describe '#rename_project' do
    # Can't use let_it_be because we change the path
    let(:project) { create(:project) }
    let(:new_path) { project.path.succ }
    let(:meth) { 'rename_project' }

    # Store the path before we change it
    let!(:args) { [project.path, new_path, project.namespace.full_path] }

    include_examples 'moving a pages directory' do
      before do
        project.update!(path: new_path)
      end
    end
  end

  describe '#rename_namespace' do
    # Can't use let_it_be because we change the path
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:new_path) { project.namespace.full_path.succ }
    let(:meth) { 'rename_namespace' }

    # Store the path before we change it
    let!(:args) { [project.namespace.full_path, new_path] }

    before do
      # We need to skip hooks, otherwise the directory will be moved
      # via an ActiveRecord callback
      group.update_columns(path: new_path)
      group.route.update!(path: new_path)
    end

    include_examples 'moving a pages directory'
  end
end
