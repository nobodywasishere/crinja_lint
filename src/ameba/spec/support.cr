# Require this file to load code that supports testing Ameba rules.

require "./be_valid"
require "./expect_issue"
require "./util"

module Ameba
  class Source
    include Spec::Util

    def self.new(code : String, path : String, normalize : Bool) : self
      code = normalize ? normalize_code(code) : code
      new(code, path)
    end
  end
end

include Ameba::Spec::BeValid
include Ameba::Spec::ExpectIssue
