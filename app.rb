# -*- encoding : utf-8 -*-

require 'sinatra'
require 'csv'

set :csvfile, 'fakedata.csv'
set :public_folder, File.dirname(__FILE__) + '/static'


before do
  @contacts = []
  CSV.parse(File.read(settings.csvfile), headers: :first_row).each do |row|
    @contacts << row.to_hash
  end

end

helpers do

  def get_and_show_id(arr)
    id = arr.shift
    sprintf('<td><a href="/contacts/%d">%d</a></td>', id, id)
  end

  def save_csv(contacts)
    CSV.open(settings.csvfile ,'wb') do |csv|
      csv << contacts.first.keys
      contacts.each do |h|
        csv << h.values
      end
    end
  end

end

get '/' do
  redirect '/contacts'
end

get '/contacts' do
  @headers = @contacts.first.keys
  if params[:name_like]
    @contacts = @contacts.select{|contact| contact["name"].include?(params[:name_like])  }
  end
  erb :index
end

post '/contacts' do
  number_of_contacts = @contacts.length
  next_id = number_of_contacts + 1
  date = Date.today.strftime("%Y/%-m/%-d")
  @contacts << {
    id: next_id,
    name: params[:contact][:name],
    phone: params[:contact][:phone],
    address: params[:contact][:address],
    created_on: date,
    note: params[:contact][:note]
  }
  save_csv(@contacts)
  redirect '/contacts'
end

get '/contacts/new' do
  @action = "/contacts"
  @method = :post
  erb :new
end

before %r{\/contacts\/(\d+).*} do
  @contact = @contacts.select{|contact| contact["id"] == params[:captures].first}
  not_found if @contact.empty?
  @contact = @contact.first
end

put '/contacts/:id' do
  @contacts[params[:id].to_i - 1].merge! params[:contact]
  save_csv(@contacts)
  redirect '/contacts'
end

get '/contacts/:id/edit' do
  @action = "/contacts/#{@contact['id']}"
  @method = :put
  erb :form
end

delete '/contacts/:id' do
  @contacts.reject! { |contact| contact['id'] == params[:id] }
  save_csv(@contacts)
  redirect '/contacts'
end

get '/contacts/:id' do
  erb :show
end