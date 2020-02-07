require 'rexml/document'
require 'byebug'

module RuboCop
  module Formatter
    class JUnitFormatter < BaseFormatter

      # This gives all cops - we really want all _enabled_ cops, but
      # that is difficult to obtain - no access to config object here.
      COPS = Cop::Cop.all
      
      def started(target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @testsuites = REXML::Element.new('testsuites', @document)
        @testsuite = REXML::Element.new('testsuite', @testsuites).tap do |el|
          el.add_attributes('name' => 'rubocop')
        end
      end

      def file_finished(file, offences)
        return if offences.length.zero?
        
        results = Hash.new { |hash, key| hash[key] = [] }
        offences.reduce(results) do |memo, offence|
          memo[offence.cop_name] << offence
          memo
        end
        
        results.keys.sort.each do |cop_name|
          REXML::Element.new('testcase', @testsuite).tap do |f|
            f.attributes['classname'] = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').gsub('/', '.')
            f.attributes['name']      = cop_name
            
            type_count = 0
            offences.select { |offence| offence.cop_name == cop_name}.each do |offence|
              REXML::Element.new('failure', f).tap do |e|
                e.attributes['type']    = "#{cop_name}-#{type_count}"
                e.attributes['message'] = offence.message
                e.add_text offence.location.to_s
              end
            end
          end
        end
      end
      
      def finished(inspected_files)
        @document.write(output, 2)
      end
    end
  end
end
