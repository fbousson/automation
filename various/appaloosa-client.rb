#!/usr/bin/ruby
# 
# based on https://github.com/lacostej/appaloosa-store-ruby
# 

require 'rubygems'
require 'mechanize'
require 'json'
require 'pathname'

STDOUT.sync = true

class Appaloosa 
  def initialize(token)
    puts "INFO: Current directory: #{Dir.pwd}"

    @token = token
    @errors = 0    
    @baseUrl = "https://www.appaloosa-store.com"
    @agent = Mechanize.new
    
    proxy = ENV["http_proxy"]
    if(proxy!=nil)
    	proxy = proxy.gsub("http://","")
        puts "INFO: Using proxy: #{proxy}"
    	proxy = proxy.split(":")
    	@agent.set_proxy(proxy.first,proxy.last)
    end
  end
  
  def errors
    @errors
  end
  
  class NotificationUpdate
    def initialize(json)
      @json = json
    end
    def json
      @json
    end
    def id
      @json['id']
    end
    def status
      return -1 if @json['status'].nil?
      @json['status'].to_i
    end
    def application_id
      @json['application_id']
    end
    def status_message
      @json['status_message']
    end
    def hasError
      status > 4
    end
    def to_s
      @json.to_json
    end
    def isProcessed
      hasError() or (!application_id.nil? and application_id != '')
    end
  end
  
  def deployFile(token, file)
    uploadForm = getUploadForm(token)
    puts "INFO: Uploading to Appaloosa..."
    uploadFile(file, uploadForm)
    puts "INFO: Upload done"
    notification = notifyAppaloosaForFile(file, token, uploadForm)
    while (!notification.isProcessed())
      puts "INFO: Upload not yet processed at Appaloosa: #{notification}"
      sleep 5
      notification = getNotificationUpdate(notification.id, token)
    end
    if (notification.hasError)
      status_message = notification.status_message.gsub("<br/>"," ")
      puts "ERROR: Deployment failed: #{status_message}"
      @errors += 1
      return
    end
    notification = publish(notification, token)
    puts "INFO: Successfully deployed: #{notification}"    
    notification
  end
  
  def publish(notification, token)
    r = @agent.post("#{@baseUrl}/api/publish_update.json", {
      "token" => token,
      "id" => notification.id.to_s
    })
    NotificationUpdate.new(JSON r.content)
  end
  
  def getNotificationUpdate(id, token)
    url = "#{@baseUrl}/mobile_application_updates/#{id}.json?token=#{token}"
    form = @agent.get(url).content
    json = JSON form
    return NotificationUpdate.new(json)
  end
  
  def getUploadForm(token)
    form = @agent.get("#{@baseUrl}/api/upload_binary_form.json?token=#{token}").content
    JSON form
  end
  
  def uploadFile(file, json)
    r = @agent.post(json['url'], {
      "policy" => json['policy'],
      "success_action_status" => json['success_action_status'],
      "Content-Type" => json['content_type'],
      "signature" => json['signature'],
      "AWSAccessKeyId" => json['access_key'],
      "key" => json['key'],
      "acl" => json['acl'],
      "file" => File.new(file)
    })
  end
  
  def notifyAppaloosaForFile(file, token, json)
    key = json['key']
    key["${filename}"] = Pathname.new(file).basename.to_s
    r = @agent.post("#{@baseUrl}/api/on_binary_upload", {
      "token" => token,
      "key" => key
    })
    NotificationUpdate.new(JSON r.content)
  end
  
  def processFiles(pattern, dir)
    files = findFiles(pattern,dir)

    if files.count > 0
      for file in files
        puts "INFO: Found #{file}"
      deployFile(@token,file)
      end
    elsif
      puts "ERROR: No files matched #{pattern}"
    end
  end
  
  def findFiles(pattern, dir)
    if pattern == nil
      pattern = "((\.ipa)|(\.apk))$"
    end
    
    if dir == nil
      dir = "."
    end
      
    result = Array.new
    
    Dir.foreach(dir) do |file|
      path = dir+"/"+file
      next if file =~ /^\./
      if(File.directory?path)
        result.concat findFiles(pattern,path)
      elsif((path =~ /#{pattern}/) != nil)
        result.push path
      end
    end
    
    result
  end
end

#cztua6vj3uptyqeaoo4bujf2tl143aaf **/*signed-aligned.apk
store = Appaloosa.new(ARGV[0])
store.processFiles(ARGV[2],ARGV[1])

exit store.errors
