require 'rubygems'
require 'savon'
require 'yaml'

liveurl = 'https://developer-api.affili.net'
devurl  = 'https://api.affili.net'

logonurl = '/V2.0/Logon.svc?wsdl'

logonclient = Savon::Client.new do
  wsdl.document = devurl + logonurl
end

puts logonclient.wsdl.soap_actions

response = logonclient.request :wsdl, :logon do
  soap.body = {
    'Username' => '',
    'Password' => '',
    'WebServiceType' => 'Publisher',
    'DeveloperSettings' => {
      'SandboxPublisherID' => '0'
    }
  }
end