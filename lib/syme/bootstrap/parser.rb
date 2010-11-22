module Syme
  class Parser
    def initialize
      @error_position = 0
    end

    # The #parse_string method is defined in the parser C extension.

    def parse(string)
      @string = string
      ast = parse_string string
      show_syntax_error unless ast
      ast
    end

    def parse_file(name)
      string = IO.read name
      parse string
    end

    # Parsing callbacks

    def show_syntax_error
      error_line = nil
      count = 0

      @string.each_line do |line|
        count += line.size
        if count > @error_position
          error_line = line
          break
        end
      end

      message = <<-EOM

#{error_line.chomp}
#{" " *(error_line.size - (count - @error_position))}^
EOM
      raise Syntax::SyntaxError, message
    end

    def syntax_error(pos)
      @error_position = pos
    end
  end
end

require 'syme/bootstrap/parser/ext/parser'
