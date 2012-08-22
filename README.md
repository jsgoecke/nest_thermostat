# nest_thermostat

![Build Status](https://secure.travis-ci.org/jsgoecke/nest_thermostat.png)

A Ruby library for controlling the [Nest Thermostat](http://nest.com).

## Installation

```
gem install nest_thermostat
```

## Usage

```ruby
require 'nest_thermostat'

nest = NestThermostat.new :username => 'foo', :password => 'bar'

nest.credentials
#{"is_superuser"=>false, "is_staff"=>false, "urls"=>{"transport_url"=>"https://25.transport.nest.com:9443", "rubyapi_url"=>"https://home.nest.com/", "weather_url"=>"http://www.wunderground.com/auto/nestlabs/geo/current/i?query="}, "limits"=>{"thermostats_per_structure"=>10, "structures"=>2, "thermostats"=>10}, "access_token"=>"foo", "userid"=>"1234", "expires_in"=>"Fri, 21-Sep-2012 01:08:00 GMT", "email"=>"foo@bar.com", "user"=>"user.1234"}

# By default the library uses Farenheit
nest.current_temperature
# 75

nest.set_temperature 65
# true

nest.status
# Returns a large hash with detail on the current status of the thermostat and environment
```

## Credits & Disclaimer

This library builds upon the work done in Python by [@smbaker](https://github.com/smbaker) creating the [pynest](https://github.com/smbaker/pynest) tool. The library should be considered experimental, as the library is using an unpublished API for the Nest website that is subject to change without notice.

## Copyright

Copyright (c) 2012 Jason Goecke. See LICENSE.txt for further details.

