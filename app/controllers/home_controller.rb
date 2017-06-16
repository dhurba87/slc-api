class HomeController < ApplicationController
  def index
    require 'nokogiri'
    require 'uri'
    require 'net/http'

    symbol = params[:symbol]
    dob = params[:dob]

    if !symbol && !dob
      render json: {status: :error, message: 'Please provide symbol and dob.' }
    else
      url = URI("http://www.see.ntc.net.np/gradesheet.php")

      http = Net::HTTP.new(url.host, url.port)

      request = Net::HTTP::Post.new(url)
      request["cache-control"] = 'no-cache'
      request["content-type"] = 'application/x-www-form-urlencoded'
      request["postman-token"] = '599ea332-9b96-30b2-39df-aa0045b19b9d'
      request.body = "symbol=#{symbol}&dob=#{dob}&submit=View%20Grade%20Sheet"

      response = http.request(request)
      html_body = response.read_body

      r = Nokogiri::HTML(html_body).css('table')
      unless r.any?
        render json: {status: :error, message: 'Not found. Please recheck and try again.'}
      else
        result_td = r.css('tr')[3].css('td')

        data = []
        data_index = ['SN','Subjects', 'Crdit Hours','TH','PR','Final Grade','Grade Point','Remarks']
        result_td.each_with_index do |td, index|
          td_child = td.css('div')
          td_child.search('br').each do |td_text|
            td_text.replace(',')
          end
          data << td_child.text.lstrip.rstrip.chomp(',')
        end
        arr_data = []
        data.each_with_index do |dat, index|
          arr_data << { data_index[index] => dat.split(',') }
        end
        render json: {status: :success, data: arr_data }
      end
    end
  end
end
