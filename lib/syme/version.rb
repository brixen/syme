module Syme
  module VERSION
    MAJOR = 0
    MINOR = 0
    TINY  = 1
    BUILD = nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end

  def VERSION.to_s
    self::STRING
  end
end
