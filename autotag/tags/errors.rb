module Autotag::Tags
  module Errors
    
    class TagError < RuntimeError; end
    
    class CreateNotSupported < TagError; end
    class InvalidTag < TagError; end
    class TagNotFound < TagError; end
    
  end
end
