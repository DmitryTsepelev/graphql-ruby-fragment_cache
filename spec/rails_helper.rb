# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "spec_helper"
require "combustion"
require "graphql/fragment_cache/railtie"

Combustion.initialize! :active_record
