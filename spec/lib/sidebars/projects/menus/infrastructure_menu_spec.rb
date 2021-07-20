# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::InfrastructureMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: false) }

  describe '#render?' do
    subject { described_class.new(context) }

    context 'when menu does not have any menu items' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to be false
      end
    end

    context 'when menu has menu items' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end
  end

  describe '#link' do
    subject { described_class.new(context) }

    context 'when Kubernetes menu item is visible' do
      it 'menu link points to Kubernetes page' do
        expect(subject.link).to eq find_menu_item(:kubernetes).link
      end
    end

    context 'when Kubernetes menu item is not visible' do
      before do
        subject.renderable_items.delete(find_menu_item(:kubernetes))
      end

      it 'menu link points to Serverless page' do
        expect(subject.link).to eq find_menu_item(:serverless).link
      end

      context 'when Serverless menu is not visible' do
        before do
          subject.renderable_items.delete(find_menu_item(:serverless))
        end

        it 'menu link points to Terraform page' do
          expect(subject.link).to eq find_menu_item(:terraform).link
        end
      end
    end

    def find_menu_item(menu_item)
      subject.renderable_items.find { |i| i.item_id == menu_item }
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Kubernetes' do
      let(:item_id) { :kubernetes }

      it_behaves_like 'access rights checks'
    end

    describe 'Serverless' do
      let(:item_id) { :serverless }

      it_behaves_like 'access rights checks'
    end

    describe 'Terraform' do
      let(:item_id) { :terraform }

      it_behaves_like 'access rights checks'
    end
  end
end
