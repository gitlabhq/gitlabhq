# frozen_string_literal: true
require 'spec_helper'

describe SortingHelper do
  include ApplicationHelper
  include IconsHelper
  include ExploreHelper

  describe '#issuable_sort_option_title' do
    it 'returns correct title for issuable_sort_option_overrides key' do
      expect(issuable_sort_option_title('created_asc')).to eq('Created date')
    end

    it 'returns correct title for a valid sort value' do
      expect(issuable_sort_option_title('priority')).to eq('Priority')
    end

    it 'returns nil for invalid sort value' do
      expect(issuable_sort_option_title('invalid_key')).to eq(nil)
    end
  end

  describe '#issuable_sort_direction_button' do
    before do
      allow(self).to receive(:request).and_return(double(path: 'http://test.com', query_parameters: { label_name: 'test_label' }))
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

  # TODO: need separate tests for /admin/projects and /projects
  # TODO: should this be renamed to `projects_sort_option_title??` ... maybe not
  def stub_controller_path(value)
    allow(helper.controller).to receive(:controller_path).and_return(value)
  end

  def project_common_options
    {
      sort_value_latest_activity  => sort_title_latest_activity,
      sort_value_recently_created => sort_title_created_date,
      sort_value_name             => sort_title_name,
      sort_value_stars_desc       => sort_title_stars
    }
  end

  describe 'with `admin/projects` controller' do
    before do
      stub_controller_path('admin/projects')
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        hash = projects_sort_options_hash

        admin_options = project_common_options.merge(    {
          sort_value_oldest_activity  => sort_title_oldest_activity,
          sort_value_oldest_created   => sort_title_oldest_created,
          sort_value_recently_created => sort_title_recently_created,
          sort_value_stars_desc       => sort_title_most_stars,
          sort_value_largest_repo     => sort_title_largest_repo
        })
        expect(hash).to eq(admin_options)
      end
    end
  end

  describe 'with `projects` controller' do
    before do
      stub_controller_path('projects')
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        hash = projects_sort_options_hash
        common_options = project_common_options

        common_options.each do |key, opt|
          expect(hash).to include(key)
          expect(hash[key]).to eq(opt)
        end
      end
    end

    describe '#projects_reverse_sort_options_hash' do 
      it 'returns a reversed hash of available sorting options' do
        reverse_hash = projects_reverse_sort_options_hash

        options = {
          sort_value_latest_activity  => sort_value_oldest_activity,
          sort_value_recently_created => sort_value_oldest_created,
          sort_value_name             => sort_value_name_desc,
          sort_value_stars_desc       => sort_value_stars_asc,
          sort_value_oldest_activity  => sort_value_latest_activity,
          sort_value_oldest_created   => sort_value_recently_created,
          sort_value_name_desc        => sort_value_name,
          sort_value_stars_asc        => sort_value_stars_desc
        }

        options.each do |key, opt|
          expect(reverse_hash).to include(key)
          expect(reverse_hash[key]).to eq(opt)
        end
      end
    end

    describe '#project_sort_direction_button' do
      # TODO: add more of these
      # TODO: Not too sure about these
      # Take a look at the ui and just go with that
      # it 'returns icon with sort-highest when sort is created_date' do
      #   expect(project_sort_direction_button('created_date')).to include('sort-highest')
      # end

      # it 'returns icon with sort-lowest when sort is asc' do
      #   expect(project_sort_direction_button('created_asc')).to include('sort-lowest')
      # end

      # it 'returns icon with sort-lowest when sorting by milestone' do
      #   expect(project_sort_direction_button('milestone')).to include('sort-lowest')
      # end

      # it 'returns icon with sort-lowest when sorting by due_date' do
      #   expect(project_sort_direction_button('due_date')).to include('sort-lowest')
      # end
    end

    describe '#projects_sort_option_titles' do
      it 'returns a hash of titles for the sorting options' do
        titles = projects_sort_option_titles

        options = {
          sort_value_latest_activity  => sort_title_latest_activity,
          sort_value_recently_created => sort_title_created_date,
          sort_value_name             => sort_title_name,
          sort_value_stars_desc       => sort_title_stars,
          sort_value_oldest_activity  => sort_title_latest_activity,
          sort_value_oldest_created   => sort_title_created_date,
          sort_value_name_desc        => sort_title_name,
          sort_value_stars_asc        => sort_title_stars
        }

        expect(titles.length).to eq(options.length)

        titles.each do |key, opt|
          expect(options).to include(key)
          expect(options[key]).to eq(opt)
        end
      end
    end

    describe 'with project_list_filter_bar off' do
      before do
        stub_feature_flags(project_list_filter_bar: false)
      end

      describe '#projects_sort_options_hash' do
        it 'returns a hash of available sorting options' do
          hash = projects_sort_options_hash
          options = project_common_options.merge({
            sort_value_oldest_activity  => sort_title_oldest_activity,
            sort_value_oldest_created   => sort_title_oldest_created,
            sort_value_recently_created => sort_title_recently_created,
            sort_value_stars_desc       => sort_title_most_stars
          })

          options.each do |key, opt|
            expect(hash).to include(key)
            expect(hash[key]).to eq(opt)
          end
        end
      end

      describe '#projects_reverse_sort_options_hash' do 
        it 'returns a reversed hash of available sorting options' do
          reverse_hash = projects_reverse_sort_options_hash

          options = {
            sort_value_latest_activity  => sort_value_oldest_activity,
            sort_value_recently_created => sort_value_oldest_created,
            sort_value_name             => sort_value_name_desc,
            sort_value_stars_desc       => sort_value_stars_asc,
            sort_value_oldest_activity  => sort_value_latest_activity,
            sort_value_oldest_created   => sort_value_recently_created,
            sort_value_name_desc        => sort_value_name,
            sort_value_stars_asc        => sort_value_stars_desc
          }

          options.each do |key, opt|
            expect(reverse_hash).to include(key)
            expect(reverse_hash[key]).to eq(opt)
          end
        end
      end

      describe '#project_sort_direction_button' do
        # TODO: these don't look correct
        # it 'returns icon with sort-highest when sort is created_date' do
        #   expect(project_sort_direction_button('created_date')).to include('sort-highest')
        # end

        # it 'returns icon with sort-lowest when sort is asc' do
        #   expect(project_sort_direction_button('created_asc')).to include('sort-lowest')
        # end

        # it 'returns icon with sort-lowest when sorting by milestone' do
        #   expect(project_sort_direction_button('milestone')).to include('sort-lowest')
        # end

        # it 'returns icon with sort-lowest when sorting by due_date' do
        #   expect(project_sort_direction_button('due_date')).to include('sort-lowest')
        # end
      end
    end
  end
end
