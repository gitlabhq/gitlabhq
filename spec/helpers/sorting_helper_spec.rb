# frozen_string_literal: true
require 'spec_helper'

RSpec.describe SortingHelper, feature_category: :shared do
  include ApplicationHelper
  include IconsHelper
  include ExploreHelper

  def set_sorting_url(option)
    allow(self).to receive(:request).and_return(double(path: 'http://test.com', query_parameters: { label_name: option }))
  end

  describe '#issuable_sort_options' do
    let(:viewing_issues) { false }
    let(:viewing_merge_requests) { false }
    let(:params) { {} }

    subject(:options) { helper.issuable_sort_options(viewing_issues, viewing_merge_requests) }

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    shared_examples 'with merged date option' do
      it 'adds merged date option' do
        expect(options).to include(
          a_hash_including(
            value: 'merged_at',
            text: 'Merged date'
          )
        )
      end
    end

    shared_examples 'without merged date option' do
      it 'does not set merged date option' do
        expect(options).not_to include(
          a_hash_including(
            value: 'merged_at',
            text: 'Merged date'
          )
        )
      end
    end

    it_behaves_like 'without merged date option'

    context 'when viewing_merge_requests is true' do
      let(:viewing_merge_requests) { true }

      it_behaves_like 'without merged date option'

      context 'when state param is all' do
        let(:params) { { state: 'all' } }

        it_behaves_like 'with merged date option'
      end

      context 'when state param is merged' do
        let(:params) { { state: 'merged' } }

        it_behaves_like 'with merged date option'
      end
    end
  end

  describe '#admin_users_sort_options' do
    it 'returns correct link attributes in array' do
      options = admin_users_sort_options(filter: 'filter', search_query: 'search')

      expect(options[0][:href]).to include('filter')
      expect(options[0][:href]).to include('search')
      options.each do |option|
        expect(option[:href]).to include(option[:value])
      end
    end
  end

  describe '#issuable_sort_direction_button' do
    before do
      set_sorting_url 'test_label'
    end

    it 'keeps label filter param' do
      expect(issuable_sort_direction_button('created_date')).to include('label_name=test_label')
    end

    it 'returns icon with sort-highest when sort is created_date' do
      expect(issuable_sort_direction_button('created_date')).to include('sort-highest')
    end

    it 'returns icon with sort-lowest when sort is asc' do
      expect(issuable_sort_direction_button('created_asc')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by milestone' do
      expect(issuable_sort_direction_button('milestone')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by due_date' do
      expect(issuable_sort_direction_button('due_date')).to include('sort-lowest')
    end
  end

  describe '#can_sort_by_issue_weight?' do
    it 'returns false' do
      expect(helper.can_sort_by_issue_weight?(false)).to be_falsey
    end
  end

  def stub_controller_path(value)
    allow(helper.controller).to receive(:controller_path).and_return(value)
  end

  def project_common_options
    {
      sort_value_latest_activity => sort_title_latest_activity,
      sort_value_recently_created => sort_title_created_date,
      sort_value_name => sort_title_name,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_stars_desc => sort_title_stars
    }
  end

  describe 'with `admin/projects` controller' do
    before do
      stub_controller_path 'admin/projects'
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        admin_options = project_common_options.merge({
          sort_value_oldest_activity => sort_title_oldest_activity,
          sort_value_oldest_created => sort_title_oldest_created,
          sort_value_recently_created => sort_title_recently_created,
          sort_value_stars_desc => sort_title_most_stars,
          sort_value_largest_repo => sort_title_largest_repo
        })

        expect(projects_sort_options_hash).to eq(admin_options)
      end
    end
  end

  describe 'with `projects` controller' do
    before do
      stub_controller_path 'projects'
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        options = project_common_options.merge({
          sort_value_oldest_activity => sort_title_oldest_activity,
          sort_value_oldest_created => sort_title_oldest_created,
          sort_value_recently_created => sort_title_recently_created,
          sort_value_stars_desc => sort_title_most_stars
        })

        expect(projects_sort_options_hash).to eq(options)
      end
    end
  end

  describe '#tags_sort_options_hash' do
    it 'returns a hash of available sorting options' do
      expect(tags_sort_options_hash).to include({
        sort_value_name => sort_title_name,
        sort_value_oldest_updated => sort_title_oldest_updated,
        sort_value_recently_updated => sort_title_recently_updated,
        sort_value_version_desc => sort_title_version_desc,
        sort_value_version_asc => sort_title_version_asc
      })
    end
  end

  describe 'with `forks` controller' do
    before do
      stub_controller_path 'forks'
    end

    describe '#forks_reverse_sort_options_hash' do
      context 'for each sort option' do
        using RSpec::Parameterized::TableSyntax

        where(:sort_key, :reverse_sort_title) do
          sort_value_recently_created | sort_value_oldest_created
          sort_value_oldest_created   | sort_value_recently_created
          sort_value_latest_activity  | sort_value_oldest_activity
          sort_value_oldest_activity  | sort_value_latest_activity
        end

        with_them do
          it 'returns the correct reversed hash' do
            reverse_hash = forks_reverse_sort_options_hash

            expect(reverse_hash).to include(sort_key)
            expect(reverse_hash[sort_key]).to eq(reverse_sort_title)
          end
        end
      end
    end

    describe '#forks_sort_direction_button' do
      context 'for each sort option' do
        using RSpec::Parameterized::TableSyntax

        sort_lowest_icon = 'sort-lowest'
        sort_highest_icon = 'sort-highest'

        where(:selected_sort, :icon) do
          sort_value_recently_created | sort_highest_icon
          sort_value_latest_activity  | sort_highest_icon
          sort_value_oldest_created   | sort_lowest_icon
          sort_value_oldest_activity  | sort_lowest_icon
        end

        with_them do
          it 'returns the correct icon' do
            set_sorting_url selected_sort

            expect(forks_sort_direction_button(selected_sort)).to include(icon)
          end
        end
      end

      it 'returns the correct link to reverse the current sort option' do
        sort_options_links = forks_reverse_sort_options_hash

        sort_options_links.each do |selected_sort, reverse_sort|
          set_sorting_url selected_sort

          expect(forks_sort_direction_button(selected_sort)).to include(reverse_sort)
        end
      end
    end
  end
end
