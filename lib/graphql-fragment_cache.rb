require "ruby-next"

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

require "graphql/fragment_cache"
