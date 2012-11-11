# encoding: UTF-8
# Bundler.require :default

# require 'sinatra'
# require 'haml'
require 'mechanize'
require 'json'

class SipgateWebApi

  attr_accessor :username
  attr_reader   :userid, :accountid
  attr_writer   :password

  @@base_url = "https://secure.live.sipgate.de"
  @@cookiepath = "cookies/"

  def initialize(username, password=nil)
    @username = username
    @password = password
    @logged_in = false
    @agent = Mechanize.new
    login
  end

  def logged_in?
    @logged_in
  end

  def extension(type=:user)
    raise "you are not logged in" unless self.logged_in?
    @extension[type]
  end

  def clip
    raise "you are not logged in" unless self.logged_in?
    page = @agent.get(@@base_url + "/settings/numberrouting/outgoing/for/register/webuser/" + @extension[:user])
    page.search("//div[@id='section_" + @extension[:mobile] + "']/span").text.gsub(/\D/, '')
  end

  def clip=(number)
    raise "you are not logged in" unless self.logged_in?
    result = @agent.post(@@base_url + "/ajax/settings/changesetting/", {
                "action" => "setOutgoing",
                "intelliRadio" => "custom",
                "outgoingNumber_radio_custom_text" => number,
                "extensionSipId" => @extension[:mobile],
                "outgoingNumber_radio" => "custom"
              })
    result = JSON.parse(result.body)
    raise result['faultString'] if result['faultCode'] != "200"
    number
  end

private

  def update_ids
    raise "you are not logged in" unless self.logged_in?
    url = @agent.get(@@base_url + "/settings").search("//li[@id='Ich']/a/@href").to_s
    match = url.match /\/settings\/phone\/index\/webuser\/(\d{7})w(\d*)$/
    @accountid = match[1]
    @userid = match[2]
  end

  def update_extensions
    raise "you are not logged in" unless self.logged_in?

    @extension = Hash.new
    @extension[:user] = @accountid + "w" + @userid

    idstring = @agent.get(@@base_url + "/settings").search('//div[starts-with(@id, "container_")]/@id').to_s
    match = idstring.match /\d{7}(y\d*)/
    @extension[:mobile] = @accountid + match[1]
  end

  def login
    unless login_with_cookie?
      login_with_form
    end

    @logged_in = true
    update_ids
    update_extensions

    # keep sessionid on save
    sessioncookie = @agent.cookie_jar.jar["secure.live.sipgate.de"]["/"]["PHPSESSID"]
    sessioncookie.session = false
    @agent.cookie_jar.save_as(@@cookiepath + @username)

    @logged_in
  end

  def login_with_cookie?
    begin
      @agent.cookie_jar.load(@@cookiepath + @username)
      page = @agent.get(@@base_url + "/")
      form = page.forms.first
      return !form.has_field?("autologin")
    rescue
      return false
    end
  end

  def login_with_form
    signin_url = @@base_url + "/signin/team"
    page = @agent.get(signin_url)
    signin_form = page.forms.first
    signin_form['username'] = @username
    signin_form['password'] = @password
    signin_form['autologin'] = "on"

    result = signin_form.submit
    raise "could not log in" if !(result.uri.to_s == @@base_url + "/")
  end

end
