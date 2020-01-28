module Arango
  class Database
    module AQLFunctions

      def list_aql_functions(namespace: nil)
        query = nil
        query = { namespace: namespace } unless namespace.nil?
        result = execute_request(get: "_api/aqlfunction", query: query)
        result.map { |r| Arango::Result.new(r) }
      end

      def create_aql_function(name, code: nil, is_deterministic: nil, &block)
        if block_given?
          source_block = Parser::CurrentRuby.parse(block.source).children.last
          source_block = source_block.children.last if source_block.type == :block
          source_code = Unparser.unparse(source_block)
          ruby_header = <<~RUBY
          args = `original_arguments`
          RUBY
          compiled_ruby= Opal.compile(ruby_header + source_code, parse_comments: false)
          if compiled_ruby.start_with?('/*')
            start_of_code = compiled_ruby.index('*/') + 3
            compiled_ruby = compiled_ruby[start_of_code..-1]
          end
          code = <<~JAVASCRIPT
          function() {
            "use strict";
            require('opal');
            var original_arguments = Array.prototype.slice.call(arguments);
            for (var i=0; i<original_arguments.length; i++) {
              if (typeof original_arguments[i] === "object" && !(original_arguments[i] instanceof Array)) {
                original_arguments[i] = Opal.Hash.$new(original_arguments[i]);
              }
            }
            var result = #{compiled_ruby}
            if (typeof result['$to_n'] === "function") { result = result['$to_n'](); }
            return result;
          }
          JAVASCRIPT
        end
        body = { code: code, name: name, isDeterministic: is_deterministic }
        result = execute_request(post: "_api/aqlfunction", body: body)
        result.response_code == 200 || result.response_code == 201
      end

      def drop_aql_function(name, group: nil)
        query = nil
        query = { group: group } unless group.nil?
        result = request(delete: "_api/aqlfunction/#{name}", query: query)
        result.response_code == 200
      end
    end
  end
end
