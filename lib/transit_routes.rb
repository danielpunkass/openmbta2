require 'database'
require 'direction'
require 'bus_routes'

class TransitRoutes
  def self.routes(route_types)
    sql = "select * from available_routes(now()) as (route_type smallint, route varchar, direction_id smallint, trips_left bigint, headsign varchar) where route_type in ? order by route, - direction_id"
    routes = DB[sql, route_types]
    res = {:data => []}
    routes.all.group_by {|x| x[:route]}.each do |route, directions|
      data = {:route_short_name => BusRoutes.abbreviate(route), :headsigns => []}
      directions.each do |d|
        direction_name = Direction.id2name(d[:direction_id], d[:headsign])  
        data[:headsigns] << [direction_name, d[:trips_left]] 
        # If subway, the v3 client expects three elements.
        # Just repeat the 1st one. Clean this up in v4
        if !([0, 1] & route_types).empty?
          data[:headsigns][-1] << direction_name
        end
      end
      res[:data] << data
    end
    # sort bus routes correctly
    res[:data] = res[:data].sort_by {|route| 
      name = route[:route_short_name]
      if name =~ /^\d+/
        "%.5d" % name[/^\d+/, 0]  # front-pad with zeros to sort correctly
      else
        name
      end
    }
    res
  end
end

if __FILE__ == $0
  require 'pp'
  pp TransitRoutes.routes([ARGV.first.to_i])
end
