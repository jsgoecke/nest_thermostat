require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "NestThermostat" do
  FakeWeb.allow_net_connect = false
  
  # Set login resource
  FakeWeb.register_uri(:get, 
                       "https://home.nest.com/user/login?username=foo%40bar.com&password=foobar", 
                       :status => ['200', 'OK'], 
                       :body   => "{\"is_superuser\":false,\"is_staff\":false,\"urls\":{\"transport_url\":\"https://25.transport.nest.com:9443\",\"rubyapi_url\":\"https://home.nest.com/\",\"weather_url\":\"http://www.wunderground.com/auto/nestlabs/geo/current/i?query=\"},\"limits\":{\"thermostats_per_structure\":10,\"structures\":2,\"thermostats\":10},\"access_token\":\"foo\",\"userid\":\"1234\",\"expires_in\":\"Fri, 21-Sep-2012 01:08:00 GMT\",\"email\":\"foo@bar.com\",\"user\":\"user.1234\"}")

  # Set status resource
  FakeWeb.register_uri(:get, 
                       "https://@25.transport.nest.com:9443/v2/mobile/user.1234", 
                       :status => ['200', 'OK'], 
                       :body   => "{\"structure\": {\"00ca7f80-b89e-11e1-8fbc-12313926e79a\":{\"devices\":[\"device.1234\"]}},\"shared\":{\"1234\":{\"current_temperature\":20.5}}}")
  
  # Set the temperature setting resource              
  FakeWeb.register_uri(:post,
                       "https://@25.transport.nest.com:9443/v2/put/shared.1234",
                       [{ :body   => '', 
                          :status => ['200', 'OK'] },
                        { :body   => 'Violation(List(target_temperature, ),260.0 is greater than maximum allowed value)',
                          :status => ['500'] },
                        { :body   => 'Violation(List(target_temperature, ),-17.77777777777778 is less than minimum allowed value)',
                          :status => ['500'] }])

  # Set the fan setting resource
  FakeWeb.register_uri(:post,
                       "https://@25.transport.nest.com:9443/v2/put/device.1234",
                       [{ :body   => '',
                          :status => ['200', 'OK'] },
                        { :body   => 'Violation(List(fan_mode, ),does not match any enum value)',
                          :status => ['500'] }])
                          
  context "invalid instantiation" do
    it "should raise an error if a Hash is not provided" do
      begin
        NestThermostat.new('foo')
      rescue => e
        e.to_s.should eql "Must provide a Hash"
      end
    end
    
    it "should raise an error if the required parameters are not provided" do
      begin 
        NestThermostat.new(:username => 'foo')
      rescue => e
        e.to_s.should eql "Must provide a :password"
      end
  
      begin 
        NestThermostat.new(:password => 'foo')
      rescue => e
        e.to_s.should eql "Must provide a :username"
      end      
    end
  end
  
  context "control thermostat" do
    let(:nest) { NestThermostat.new :username => 'foo@bar.com', :password => 'foobar' }
    
    it "should login to the site" do
      nest.credentials['userid'].should eql '1234'
    end
    
    it "should read the current temperature" do
      nest.current_temperature.should eql 69
    end
    
    it "should set the current temprature" do
      nest.set_temperature(68).should eql true
    end
    
    it "should return an error if one attempts to set the temperature to high" do
      begin
        nest.set_temperature(500)
      rescue => e
        e.to_s.should eql "Violation(List(target_temperature, ),260.0 is greater than maximum allowed value)"
      end
    end
    
    it "should return an error if one attempts to set the temperature to low" do
      begin
        nest.set_temperature(0)
      rescue => e
        e.to_s.should eql "Violation(List(target_temperature, ),-17.77777777777778 is less than minimum allowed value)"
      end
    end
    
    it "should set the fan state" do
      nest.set_fan('auto').should eql true
    end
    
    it "should throw an error if we set the fan to an invalid state" do
      begin
        nest.set_fan('superflyfast')
      rescue => e
        e.to_s.should eql "Violation(List(fan_mode, ),does not match any enum value)"
      end
    end
  end
end
