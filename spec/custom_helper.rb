require "email_spec"

module ModelError
  def self.BLANK
    /\.blank$/
  end

  def self.TAKEN
    /\.taken$/
  end

  def self.INVALID
    /\.invalid$/
  end
end

class Array
  def to_proc
    proc { |receiver| receiver.send :[], *self }
  end
end

module I18n
  class SpecErrorMessage < String
    attr_reader :key
    attr_reader :options

    def initialize key, options
      @key = key.to_s
      @options = options
      super @key
    end
  end

  def self.t(*args)
    options  = args.last.is_a?(Hash) ? args.pop.dup : {}
    key      = args.shift

    if key.is_a? Array
      key.map { |token| I18n::SpecErrorMessage.new token, options }
    else
      I18n::SpecErrorMessage.new key, options
    end
  end
end
class << I18n
  alias :origin_translate :translate
  alias :translate :t
end

RSpec.configure do |config|
  # http://simonecarletti.com/blog/2011/04/rspec-rails-doesnt-render-rails-views-by-default/
  # http://www.relishapp.com/rspec/rspec-rails/v/3-1/docs/controller-specs/render-views
  config.render_views

  # http://matthewlehner.net/rails-api-testing-guidelines/
  config.include Requests::JSONHelpers

  config.include EmailSpec::Helpers
  config.include EmailSpec::Matchers

  config.include FactoryGirl::Syntax::Methods

  config.include CustomMatchers
  config.include CustomControllerHelper, type: :controller

  config.before(type: :controller) { setup_timezone_header }
end
