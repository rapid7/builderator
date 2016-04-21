# require 'chef'
# require 'chef/cookbook_site_streaming_uploader'
# require 'rubygems/package'
# require 'thor'
# require 'thor/actions'
# require 'thor-scmversion'
# require 'zlib'
#
# require_relative '../util'
# require_relative '../util/cookbook'
#
# module Builderator
#   module Tasks
#     class Cookbook < Thor
#       include Thor::Actions
#       class_option :version, :type => :boolean,
#                              :default => true,
#                              :desc => 'Write current verison to file'
#
#       desc 'metadata [PATH]', 'Use cookbook matadata file at PATH/metadata.rb to generate PATH/matadata.json'
#       def metadata(cookbook = nil)
#         Util::Cookbook.path(cookbook) unless cookbook.nil?
#         metadata = Util::Cookbook.metadata
#
#         invoke 'version:current', [], options if options['version']
#         say_status :metadata, "for cookbook #{ metadata.name }@#{ metadata.version }"
#         create_file Util::Cookbook.path.join('metadata.json').to_s, metadata.to_json, :force => true
#
#         metadata
#       end
#
#       desc 'build PATH', 'Package cookbook at PATH into a tarball'
#       def build(cookbook = nil)
#         Util::Cookbook.path(cookbook) unless cookbook.nil?
#
#         ## Generate metadata.json
#         metadata = invoke(Tasks::Cookbook, :metadata, [], options)
#
#         ## Create a gzipped tarball and add cookbook files to it. We avoid
#         ##   buffering this in memory (e.g. using StringIO) at all cost
#         ##   to keep large files from gumming things up.
#         say_status :package, "cookbook into #{ metadata.archive }"
#         metadata.archive.open('wb') do |package|
#           Zlib::GzipWriter.wrap(package) do |gz|
#             Gem::Package::TarWriter.new(gz) do |tar|
#               metadata.files.each do |f|
#                 f_stat = File.stat(f)
#
#                 ## Add directories
#                 next tar.mkdir(Util::Cookbook.archive_path(metadata, f).to_s, f_stat.mode) if File.directory?(f)
#
#                 ## Add files
#                 tar.add_file_simple(Util::Cookbook.archive_path(metadata, f).to_s, f_stat.mode, f_stat.size) do |entry|
#                   f.open('rb') { |h| entry.write(h.read) }
#                 end
#               end
#             end
#           end
#         end
#
#         metadata
#       end
#
#       desc 'push PATH', 'Publish cookbook at PATH to supermarket.chef.io'
#       option 'chef-config', :type => :string,
#                             :aliases => :c,
#                             :default => File.join(ENV['HOME'], '.chef/knife.rb')
#       option :site, :type => :string, :aliases => :s
#       option :user, :type => :string, :aliases => :u
#       option :key, :type => :string, :aliases => :k
#       def push(cookbook = nil)
#         Chef::Config.from_file(options['chef-config'])
#         Util::Cookbook.path(cookbook) unless cookbook.nil?
#
#         ## Set defaults after Chef::Config is loaded
#         options['site'] ||= Chef::Config.knife['supermarket_site'] || 'https://supermarket.chef.io/'
#         options['user'] ||= Chef::Config.knife['supermarket_user'] || Chef::Config.node_name
#         options['key'] ||= Chef::Config.knife['supermarket_key'] || Chef::Config.client_key
#
#         ## Build the cookbook taball
#         metadata = invoke(Tasks::Cookbook, :build, [cookbook], options)
#         say_status :upload, "cookbook #{ metadata.name }@#{ metadata.version } to #{ options['site'] }"
#
#         metadata.archive.open('rb') do |c|
#           http_resp = Chef::CookbookSiteStreamingUploader.post(
#             File.join(options['site'], '/api/v1/cookbooks'),
#             options['user'],
#             options['key'],
#             :tarball => c,
#             :cookbook => { :category => '' }.to_json
#           )
#
#           if http_resp.code.to_i != 201
#             say_status :error, "Error uploading cookbook: #{ http_resp.code } #{ http_resp.message }", :red
#             say http_resp.body
#             exit(1)
#           end
#         end
#       end
#
#       desc 'version COOKBOOK', 'Print the current version of a vendored cookbook'
#       option :path, :default => Util::Cookbook::DEFAULT_VENDOR, :desc => 'Path to vendored cookbooks'
#       def version(cookbook)
#         Util::Cookbook.path(File.join(options['path'], cookbook))
#         puts Util::Cookbook.metadata.version
#       end
#     end
#   end
# end
