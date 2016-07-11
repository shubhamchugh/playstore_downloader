require "playstore_downloader/version"
require "playstore_downloader/credentials"
require "playstore_downloader/apk"
require "net/http"

module PlaystoreDownloader

  @@auth_token ||= nil

  module_function

  def req_google
    uri = URI 'http://www.google.it'
    response = Net::HTTP.get uri

    puts response
  end

  def setup(email, password, device_id)
    @@credentials = Credentials.new email, password, device_id
  end

  def auth
    uri = URI 'https://android.clients.google.com/auth'

    req = Net::HTTP::Post.new(uri)
      
    req.set_form_data(
      Email: @@credentials.email,
      Passwd: @@credentials.password,
      service: 'androidmarket',
      accountType: 'HOSTED_OR_GOOGLE',
      has_permission: 1,
      source: 'android',
      androidId: @@credentials.device_id,
      app: 'com.android.vending',
      device_country: 'it',
      operatorCountry: 'it',
      lang: 'it',
      sdk_version: 16
    )

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    res = http.request req

    @@auth_token = res.body[/(?<=Auth=).*/]
  end

  def purchase(apk)
    auth if @@auth_token.nil?

    uri = URI 'https://android.clients.google.com/fdfe/purchase'

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)

    headers = {
      Accept: 'application/xml',
      'Accept-Language':  'en_US',
      Authorization: "GoogleLogin auth=#{@@auth_token}",
      'X-DFE-Enabled-Experiments': 'cl:billing.select_add_instrument_by_default',
      'X-DFE-Unsupported-Experiments': 'nocache:billing.use_charging_poller,market_emails,buyer_currency,prod_baseline,checkin.set_asset_paid_app_field,shekel_test,content_ratings,buyer_currency_in_app,nocache:encrypted_apk,recent_changes',
      'X-DFE-Device-Id': @@credentials.device_id,
      'X-DFE-Client-Id': 'am-android-google',
      'User-Agent': 'Android-Finsky/4.7.13 (api=3,versionCode=8013013,sdk=16,device=crespo,hardware=herring,product=soju)',
      'X-DFE-SmallestScreenWidthDp': 320,
      'X-DFE-Filter-Level': 3,
      'Accept-Encoding': '',
      Host: 'android.clients.google.com'
    }

    headers.each do |key, value|
      http.add_field key, value
    end

    req.set_form_data(
      ot: apk.offer_type,
      doc: apk.package_id,
      vc: apk.version_code
    )

  end

end
