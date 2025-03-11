# frozen_string_literal: true
module PerfettoSnapshot
  def check_snapshot(data, snapshot_name)
    prev_file = caller(1, 1).first.sub(/\/[a-z_]*\.rb:.*/, "")
    snapshot_dir = prev_file + "/snapshots"
    snapshot_path = "#{snapshot_dir}/#{snapshot_name}"

    iid_table = { "debugAnnotationNames" => {}, "eventNames" => {}, "eventCategories" => {}, "debugAnnotationStringValues" => {} }
    build_intern_map(data, iid_table)

    if ENV["UPDATE_PERFETTO"]
      puts "Updating PerfettoTrace snapshot: #{snapshot_path.inspect}"
      snapshot_json = convert_to_snapshot(data, iid_table)
      FileUtils.mkdir_p(snapshot_dir)
      File.write(snapshot_path, JSON.pretty_generate(snapshot_json))
    elsif !File.exist?(snapshot_path)
      raise "Snapshot file not found: #{snapshot_path.inspect}"
    else
      snapshot_data = JSON.parse(File.read(snapshot_path))
      cleaned_data = convert_to_snapshot(data, iid_table)
      deep_snap_match(snapshot_data, cleaned_data, [])
    end
  end

  def deep_snap_match(snapshot_data, data, path)
    case snapshot_data
    when String
      assert_kind_of String, data, "Is String at #{path.join(".")}"
      if snapshot_data.match(/\D/).nil? && data.match(/\D/).nil?
        # Ok
      elsif BASE64_PATTERN.match?(snapshot_data)
        snapshot_data_decoded = Base64.decode64(snapshot_data)
        data_decoded = Base64.decode64(data)
        assert_equal snapshot_data_decoded, data_decoded, "Decoded match at #{path.join(".")}"
      else
        assert_equal snapshot_data, data, "Match at #{path.join(".")}"
      end
    when Numeric
      assert_kind_of Numeric, data, "Is numeric at #{path.join(".")}"
    when Hash
      assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
      extra_keys = snapshot_data.keys - data.keys
      extra_keys += data.keys - snapshot_data.keys
      assert_equal snapshot_data.keys.sort, data.keys.sort, "Match at #{path.join(".")} (#{extra_keys.map { |k| "#{k.inspect} => #{data[k].inspect}, snapshot: #{snapshot_data[k].inspect}"}.join(", ")})"
      snapshot_data.each do |k, v|
        next_data = data[k]
        if k == "debugAnnotations"
          next_data.sort_by! { |d| d["name"] }
        end
        deep_snap_match(v, data[k], path + [k])
      end
    when Array
      assert_equal(snapshot_data.class, data.class, "Match at #{path.join(".")}")
      snapshot_data.each_with_index do |snapshot_i, idx|
        data_i = data[idx]
        deep_snap_match(snapshot_i, data_i, path + [idx])
      end
    end
  end

  BASE64_PATTERN = /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?\n?$/

  def replace_ids(str)
    str.gsub(/ #\d+/, " #1010").split(/:0x[0-9a-z]+/).first
  end

  def convert_to_snapshot(value, iid_table)
    case value
    when String
      if value.match(/\D/).nil?
        "10101010101010"
      elsif BASE64_PATTERN.match?(value)
        decoded_value = Base64.decode64(value)
        decoded_value = replace_ids(decoded_value)
        Base64.encode64(decoded_value)
      else
        replace_ids(value)
      end
    when Numeric
      101010101010
    when Array
      value.map { |v| convert_to_snapshot(v, iid_table) }
    when Hash
      h2 = {}
      value.each do |k, v|
        case k
        when "debugAnnotations"
          v.each { |d|
            if d.key?("nameIid")
              d["name"] = iid_table["debugAnnotationNames"][d["nameIid"]]
            end
            if d.key?("stringValueIid")
              d["stringValue"] = iid_table["debugAnnotationNames"][d["stringValueIid"]]
            end
          }
          v = v.sort_by { |d| d["name"] }
        when "categoryIids"
          h2["categories"] = v.map { |ciid| iid_table["eventCategories"][ciid] }
        when "trackEvent"
          if v.key?("nameIid")
            v["name"] = iid_table["eventNames"][v["nameIid"]]
          end
        end
        h2[k] = convert_to_snapshot(v, iid_table)
      end
      h2
    when true, false, nil
      value
    else
      raise ArgumentError, "Unexpected JSON value: #{value}"
    end
  end

  def build_intern_map(data, iid_table)
    case data
    when Hash
      if (id = data["internedData"])
        id.each do |id_type, entries|
          type_table = iid_table.fetch(id_type)
          entries.each do |entry|
            type_table[entry["iid"]] = entry["name"] || (entry["str"] ? Base64.decode64(entry["str"]) : nil)
          end
        end
      end
      data.each do |k, v|
        build_intern_map(v, iid_table)
      end
    when Array
      data.each { |v| build_intern_map(v, iid_table) }
    else
      # Done
    end
  end
end
