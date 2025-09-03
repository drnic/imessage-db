# frozen_string_literal: true

module Imessage
  module Db
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
