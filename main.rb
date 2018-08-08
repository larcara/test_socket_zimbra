require 'socket'
require 'openssl'
require 'thread'
require 'open-uri'
require 'digest'
require 'httparty'
require 'rubygems'
require 'mechanize'



class Client

  def initialize(user, uri)
    @agent = Mechanize.new{ |agent|

      agent.verify_mode= OpenSSL::SSL::VERIFY_NONE}

    @pre_auth = ENV["PRE_AUTH"]
    @user = user
    @agent.get(uri)
    auth1
    inbox(10)
  end

  def compute_preauth(name, time_st, authkey)
    plaintext="#{name}|name|0|#{time_st}"
    key=authkey

    hmacd=OpenSSL::HMAC.new(key, OpenSSL::Digest::SHA1.new)
    hmacd.update(plaintext)
    return hmacd.to_s
  end


  def auth1
    time_stamp = Time.now.to_i * 1000
    @agent.get("/service/preauth?account=#{@user}&by=name&expires=0&timestamp=#{time_stamp}&preauth=#{compute_preauth(@user,time_stamp,@pre_auth)}")

    # You can also use something like:
    # get("resources", verify_peer: false)
  end
  def inbox(counter=10)
    counter.times do
      sleep rand(10)
      @agent.get("/service/home/#{@user}/Inbox?fmt=xml").body
    end

  end
end




arr = []


400.times do |i|
  arr << Thread.new {
    #puts "start trhread #{i}"
    
    begin
      sleep rand(1)
      c1=Client.new("mass#{100+i}@888.zimbra.local", "https://172.17.0.3")
    rescue Exception => e
      puts "#proxy thread #{i} exception#{e}"
      
    end
  }
  arr << Thread.new {
    begin
      sleep rand(1)
      c2=Client.new("mass#{100+i}@888.zimbra.local", "https://172.17.0.3:8443")
    rescue Exception => e
      puts "#store thread #{i} exception#{e}"
    end
  }
end
arr.map {|t| t.join}
