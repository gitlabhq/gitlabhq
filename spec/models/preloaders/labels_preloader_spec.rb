# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::LabelsPreloader do
  let_it_be(:user) { create(:user) }

  shared_examples 'an efficient database query' do
    let(:subscriptions) { labels.each { |l| create(:subscription, subscribable: l, project: l.project, user: user) }}

    it 'does not make n+1 queries' do
      first_label = labels_with_preloaded_data.first
      clean_labels = labels_with_preloaded_data

      expect { access_data(clean_labels) }.to issue_same_number_of_queries_as { access_data([first_label]) }
    end
  end

  context 'project labels' do
    let_it_be(:projects) { create_list(:project, 3, :public, :repository) }
    let_it_be(:labels) { projects.each { |p| create(:label, project: p) } }

    it_behaves_like 'an efficient database query'
  end

  context 'group labels' do
    let_it_be(:groups) { create_list(:group, 3) }
    let_it_be(:labels) { groups.each { |g| create(:group_label, group: g) } }

    it_behaves_like 'an efficient database query'
  end

  private

  def labels_with_preloaded_data
    l = Label.where(id: labels.map(&:id))
    described_class.new(l, user).preload_all
    l
  end

  def access_data(labels)
    labels.each do |label|
      if label.is_a?(ProjectLabel)
        label.project.project_feature
        label.lazy_subscription(user, label.project)
      elsif label.is_a?(GroupLabel)
        label.group.route
        label.lazy_subscription(user)
      end
    end
  end
end
