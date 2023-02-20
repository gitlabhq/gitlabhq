# frozen_string_literal: true

module ImportExport
  module ProjectTreeExpectations
    def assert_relations_match(imported_hash, exported_hash)
      normalized_imported_hash = normalize_elements(imported_hash)
      normalized_exported_hash = normalize_elements(exported_hash)

      # this is for sanity checking, to make sure we didn't accidentally pass the test
      # because we essentially ignored everything
      stats = {
        hashes: 0,
        arrays: {
          direct: 0,
          pairwise: 0,
          fuzzy: 0
        },
        values: 0
      }

      failures = match_recursively(normalized_imported_hash, normalized_exported_hash, stats)

      puts "Elements checked:\n#{stats.pretty_inspect}"

      expect(failures).to be_empty, failures.join("\n\n")
    end

    private

    def match_recursively(left_node, right_node, stats, location_stack = [], failures = [])
      if Hash === left_node && Hash === right_node
        match_hashes(left_node, right_node, stats, location_stack, failures)
      elsif Array === left_node && Array === right_node
        match_arrays(left_node, right_node, stats, location_stack, failures)
      else
        stats[:values] += 1
        if left_node != right_node
          failures << failure_message("Value mismatch", location_stack, left_node, right_node)
        end
      end

      failures
    end

    def match_hashes(left_node, right_node, stats, location_stack, failures)
      stats[:hashes] += 1
      left_keys = left_node.keys.to_set
      right_keys = right_node.keys.to_set

      if left_keys != right_keys
        failures << failure_message("Hash keys mismatch", location_stack, left_keys, right_keys)
      end

      left_node.keys.each do |key|
        location_stack << key
        match_recursively(left_node[key], right_node[key], stats, location_stack, failures)
        location_stack.pop
      end
    end

    def match_arrays(left_node, right_node, stats, location_stack, failures)
      has_simple_elements = left_node.none?(Enumerable)
      # for simple types, we can do a direct order-less set comparison
      if has_simple_elements && left_node.to_set != right_node.to_set
        stats[:arrays][:direct] += 1
        failures << failure_message("Elements mismatch", location_stack, left_node, right_node)
      # if both arrays have the same number of complex elements, we can compare pair-wise in-order
      elsif left_node.size == right_node.size
        stats[:arrays][:pairwise] += 1
        left_node.zip(right_node).each do |left_entry, right_entry|
          match_recursively(left_entry, right_entry, stats, location_stack, failures)
        end
      # otherwise we have to fall back to a best-effort match by probing into the right array;
      # this means we will not account for elements that exist on the right, but not on the left
      else
        stats[:arrays][:fuzzy] += 1
        left_node.each do |left_entry|
          right_entry = right_node.find { |el| el == left_entry }
          match_recursively(left_entry, right_entry, stats, location_stack, failures)
        end
      end
    end

    def failure_message(what, location_stack, left_value, right_value)
      where =
        if location_stack.empty?
          "root"
        else
          location_stack.map { |loc| loc.to_sym.inspect }.join(' -> ')
        end

      ">> [#{where}] #{what}\n\n#{left_value.pretty_inspect}\nNOT EQUAL TO\n\n#{right_value.pretty_inspect}"
    end

    # Helper that traverses a project tree and normalizes data that we know
    # to vary in the process of importing (such as list order or row IDs)
    def normalize_elements(elem)
      case elem
      when Hash
        elem.to_h do |key, value|
          if ignore_key?(key, value)
            [key, :ignored]
          else
            [key, normalize_elements(value)]
          end
        end
      when Array
        elem.map { |a| normalize_elements(a) }
      else
        elem
      end
    end

    # We currently need to ignore certain entries when checking for equivalence because
    # we know them to change between imports/exports either by design or because of bugs;
    # this helper filters out these problematic nodes.
    def ignore_key?(key, value)
      id?(key) || # IDs are known to be replaced during imports
        key == 'updated_at' || # these get changed frequently during imports
        key == 'next_run_at' || # these values change based on wall clock
        key == 'notes' # the importer attaches an extra "by user XYZ" at the end of a note
    end

    def id?(key)
      key == 'id' || key.ends_with?('_id')
    end
  end
end
