# Monkey patch to handle the case where Content-Type headers returned by servers
# say "gzip" by the resulting message body isn't in gzip format.
# TODO Remove this when we upgrade Berkshelf and the gzip response goes away.
# https://github.com/berkshelf/berkshelf-api-client/blob/v1.3.0/lib/berkshelf/api_client/connection.rb#L37
require 'faraday_middleware'

module FaradayMiddleware
  class Gzip
    alias_method :__uncompress_gzip__, :uncompress_gzip
    def uncompress_gzip(body)
      __uncompress_gzip__(body)
    rescue Zlib::GzipFile::Error
      StringIO.new(body).read
    end
  end
end

Faraday::Response.register_middleware :gzip => FaradayMiddleware::Gzip

# Force Berkshelf to use the gecode dependency solver
require 'solve'

Solve.engine = :gecode
