#
# Ronin - A decentralized repository for the storage and sharing of computer
# security advisories, exploits and payloads.
#
# Copyright (c) 2007 Hal Brodigan (postmodern at users.sourceforge.net)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'repo/repository'
require 'repo/category'
require 'repo/exceptions/categorynotfound'
require 'rexml/document'

module Ronin
  module Repo

    def open_config(path=Config::CONFIG_PATH)
      $current_config = Config.new(path)
    end

    def config
      return open_config if $current_config.nil?
      return $current_config
    end

    class Config

      include REXML

      # Path to config file
      CONFIG_PATH = File.join(ENV['HOME'],'.ronin','config')

      # Path to repositories dir
      REPOS_PATH = File.join(ENV['HOME'],'.ronin','repos')

      # Path of config file
      attr_reader :path

      # Hash of loaded repositories
      attr_reader :repositories

      # Hash of all categories, each element containing the hash of
      # respositories that contain that category.
      attr_reader :categories

      def initialize(path=CONFIG_PATH)
	@path = path
        @repositories = {}
	@categories = Hash.new { |hash,key| hash[key] = {} }

	config_doc = Document.new(File.new(path))
	config_doc.elements.each('/config/repos/repo') do |repo|
	  repo_type = repo.attribute('type')
	  repo.each_element('path') { |element| repo_path = element.get_text }
	  repo.each_element('url') { |element| repo_url = element.get_text }

	  new_repo = Repository.new(repo_path,repo_url,repo_type)
	  @repositories[new_repo] = new_repo

	  new_repo.categories.each do |category|
	    @categories[category][new_repo] = new_repo
	  end
	end
      end

      def has_repository?(name)
	@repositories.has_key?(name)
      end

      def get_repository(name)
	unless has_repository?(name)
	  raise RepositoryNotFound, "repository '#{name}' not listed in config file '#{self}'", caller
	end

	return @repositories[name]
      end

      def has_category?(name)
	@categories.has_key?(name)
      end

      def get_category(name)
	unless has_category?(name)
	  raise CategoryNotFound, "category '#{name}' does not exist", caller
	end

        Category.new(name)
      end

      def to_s
	@path
      end

    end

    protected

    # Current operating configuration
    $current_config = nil
  end
end
