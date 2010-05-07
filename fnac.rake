require 'htmlentities'

namespace :events do
  namespace :fnac do
    desc('Add .xml to fnac_events table')
    task(:import_from_xml => :environment) do
      file_name = ENV['file_name'] || ENV['FILE_NAME']
      raise "Please specify a file_name" if file_name.blank?
      file_name = File.join(RAILS_ROOT, 'db', 'fnac', file_name)
      puts "Loading #{file_name}...\n"
      xml_io = open(file_name)
      puts "Loading Hpricot doc...\n"
      xml = Hpricot.XML(xml_io)
      puts "Loaded Hpricot doc...\n"
      puts "Start looping through products...\n"
      i = 1
      new_count = 0
      xml.search("//product").each do |product|
        puts "#{i} -- Product ID : #{product['id']}\n"
        fnac_event = FnacEvent.find_or_initialize_by_fnac_id(product['id'].to_i)
        if fnac_event.new_record?
          puts "#{i} -- New event\n"
          infos = product.at('info')
          fnac_event.title            = infos.at('name').inner_html.titleize
          fnac_event.url              = product.at('deeplink').inner_html
          valid_from  = product.at("date[@state='valid from']")
          valid_to    = product.at("date[@state='valid to']")
          if valid_from
            fnac_event.date_valid_from  = Time.zone.parse(valid_from.inner_html)
          end
          if valid_to
            fnac_event.date_valid_to    = Time.zone.parse(valid_to.inner_html) 
          end
          unless fnac_event.date_valid_from.blank? || fnac_event.date_valid_to.blank?
            # fnac doesn't specify correctly date for event which occurs during only day only
            # because then valid_from and valid_to date are equal
            # we add one day to valid_to datetime
            if fnac_event.date_valid_from == fnac_event.date_valid_to
              puts "#{i} -- Date collision\n"
              fnac_event.date_valid_to = fnac_event.date_valid_to + 1.day
              puts "#{i} -- Date collision corrected\n"
            end
          end
          fnac_event.price            = product.at("currentprice").inner_html
          fnac_event.affiliate_url    = fnac_event.url
          #fnac_event.fnac_id          = 
          fnac_event.fnac_name        = product['number']
          merchant = product.at("merchant")
          categories = merchant.inner_html.split(' ; ').collect { |c| c.split('/') }.flatten.collect { |c| c.strip } if merchant
          if categories
            fnac_event.genre1           = categories.include?('1MC')
            fnac_event.genre2           = categories.include?('2TH')
            fnac_event.genre3           = categories.include?('3DA')
            fnac_event.genre4           = categories.include?('4SP')
            fnac_event.genre5           = categories.include?('5FA')
            fnac_event.genre6           = categories.include?('6AR')
            fnac_event.genre7           = categories.include?('7TL')
            fnac_event.genre8           = categories.include?('8CI')
          end
          publisher = product.at("extratext[@number='3']")
          if publisher
            publisher = publisher.inner_html.split(' ; ').first.split('|').collect { |n| n.titleize  }
            fnac_event.publisher        = "#{publisher.third} #{publisher.second}".strip
          end
          manufacturer = product.at("manufacturer")
          fnac_event.place_name       = manufacturer.inner_html.titleize if manufacturer
          fnac_event.place_fnac_name  = product.at("extratext[@number='1']").inner_html
          geoloc = product.at("shippinghandling").inner_html.split("|")
          fnac_event.place_lat        = geoloc[3]
          fnac_event.place_lng        = geoloc[2]
          address = product.at("description[@state='long']")
          fnac_event.place_address    = address.inner_html.titleize if address
          city = product.at("extratext[@number='2']")
          fnac_event.place_city       = city.inner_html.titleize if city
          zipcode = infos.at("terms")
          fnac_event.place_zipcode    = zipcode.inner_html if zipcode
          #fnac_event.place_region     = nil
          country = product.at("description[@state='short']")
          fnac_event.place_country    = country.inner_html if country
          puts "#{i} -- #{fnac_event.inspect}\n"
          fnac_event.save!          
          puts "#{i} -- record save #{fnac_event.id}\n"
          new_count += 1
        else
          puts "#{i} -- Already in our base\n"
        end
        i += 1
      end
      puts "End looping through products...\n"
      puts "Run ts:index task...\n"
      Rake::Task["thinking_sphinx:index"].execute
      puts "Everything is good ! #{new_count} new events...\n"
      # run rake task : rake ts:index
    end
  end
end